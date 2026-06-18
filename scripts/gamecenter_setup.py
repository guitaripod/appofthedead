#!/usr/bin/env python3
# pyright: reportArgumentType=false, reportIndexIssue=false, reportOptionalSubscript=false
"""Provision App of the Dead's Game Center configuration via the App Store Connect API.

Reads ASC creds from the environment (source ~/.config/midgar/credentials.env first):
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_PATH

Phases (idempotent — skips records that already exist by vendorIdentifier):
  discover    read-only: app, bundle-id capability, gameCenterDetail, existing boards/achievements
  capability  enable GAME_CENTER on the bundle id
  detail      ensure the app's gameCenterDetail exists
  leaderboards   create the 5 classic leaderboards + en-US localizations
  achievements   create the 10 achievements + en-US localizations
  all         capability -> detail -> leaderboards -> achievements

Achievement artwork is uploaded separately by gamecenter_images.py (needs the PNGs).
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

import jwt

APP_ID = "6746733380"
BUNDLE_ID = "com.marcusziade.aotd"
BASE = "https://api.appstoreconnect.apple.com"

LEADERBOARDS = [
    ("com.marcusziade.aotd.leaderboard.total_xp", "Total Enlightenment", "XP"),
    ("com.marcusziade.aotd.leaderboard.current_streak", "Days of Devotion", "days"),
    ("com.marcusziade.aotd.leaderboard.paths_mastered", "Realms Mastered", "realms"),
    ("com.marcusziade.aotd.leaderboard.paths_completed", "Gates Walked", "gates"),
    ("com.marcusziade.aotd.leaderboard.correct_answers", "Sacred Knowledge", "answers"),
]

# vendorIdentifier, name, points, before/after description
ACHIEVEMENTS = [
    ("first_step", "First Step", 20, "Complete your first lesson."),
    ("quiz_whiz", "Quiz Whiz", 40, "Answer 50 questions correctly."),
    ("enlightened_one", "Enlightened One", 60, "Earn 500 total XP."),
    ("perfect_understanding", "Perfect Understanding", 60, "Get 100% on any mastery test."),
    ("scholar_of_sheol", "Scholar of Sheol", 70, "Complete the Judaism path."),
    ("journey_through_duat", "Journey Through Duat", 70, "Complete the Egyptian Afterlife path."),
    ("wisdom_seeker", "Wisdom Seeker", 80, "Earn 1000 total XP."),
    ("eternal_student", "Eternal Student", 100, "Complete 3 belief system paths."),
    ("cosmic_explorer", "Cosmic Explorer", 100, "Complete 5 belief system paths."),
    ("afterlife_master", "Afterlife Master", 100, "Complete all belief system paths."),
]


def token():
    key_id = os.environ["ASC_KEY_ID"]
    issuer = os.environ["ASC_ISSUER_ID"]
    with open(os.environ["ASC_PRIVATE_KEY_PATH"]) as f:
        private_key = f.read()
    now = int(time.time())
    payload = {"iss": issuer, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": key_id})


_TOKEN = None


def req(method, path, body=None, expect=(200, 201)):
    global _TOKEN
    if _TOKEN is None:
        _TOKEN = token()
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", "Bearer " + _TOKEN)
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            parsed = json.loads(raw)
        except Exception:
            parsed = {"raw": raw.decode(errors="replace")}
        return e.code, parsed


def first_error(payload):
    errs = payload.get("errors") if isinstance(payload, dict) else None
    if not errs:
        return json.dumps(payload)[:500]
    e = errs[0]
    return f"{e.get('status')} {e.get('code')}: {e.get('title')} — {e.get('detail')}"


def get_bundle():
    s, p = req("GET", f"/v1/bundleIds?filter[identifier]={BUNDLE_ID}&include=bundleIdCapabilities")
    if s != 200 or not p.get("data"):
        return None, []
    bid = p["data"][0]
    caps = [i["attributes"]["capabilityType"]
            for i in p.get("included", []) if i["type"] == "bundleIdCapabilities"]
    return bid["id"], caps


def get_detail_id():
    s, p = req("GET", f"/v1/apps/{APP_ID}/gameCenterDetail")
    if s == 200 and p.get("data"):
        return p["data"]["id"]
    return None


def list_existing(detail_id):
    boards, achs = {}, {}
    if not detail_id:
        return boards, achs
    s, p = req("GET", f"/v1/gameCenterDetails/{detail_id}/gameCenterLeaderboards?limit=200")
    for d in (p.get("data", []) if s == 200 else []):
        boards[d["attributes"]["vendorIdentifier"]] = d["id"]
    s, p = req("GET", f"/v1/gameCenterDetails/{detail_id}/gameCenterAchievements?limit=200")
    for d in (p.get("data", []) if s == 200 else []):
        achs[d["attributes"]["vendorIdentifier"]] = d["id"]
    return boards, achs


def discover():
    s, p = req("GET", f"/v1/apps/{APP_ID}?fields[apps]=name,bundleId")
    if s != 200:
        print("AUTH/APP FETCH FAILED:", first_error(p)); sys.exit(1)
    print(f"App: {p['data']['attributes']['name']} ({p['data']['attributes']['bundleId']})")
    bundle_id, caps = get_bundle()
    print(f"Bundle resource: {bundle_id}")
    print(f"  GAME_CENTER enabled: {'GAME_CENTER' in caps}  (capabilities: {sorted(caps)})")
    detail_id = get_detail_id()
    print(f"gameCenterDetail: {detail_id or 'NONE'}")
    boards, achs = list_existing(detail_id)
    print(f"Existing leaderboards ({len(boards)}): {sorted(boards)}")
    print(f"Existing achievements ({len(achs)}): {sorted(achs)}")
    return bundle_id, caps, detail_id, boards, achs


def enable_capability():
    bundle_id, caps = get_bundle()
    if "GAME_CENTER" in caps:
        print("GAME_CENTER already enabled.")
        return
    s, p = req("POST", "/v1/bundleIdCapabilities", {
        "data": {
            "type": "bundleIdCapabilities",
            "attributes": {"capabilityType": "GAME_CENTER"},
            "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id}}},
        }
    })
    print("enable GAME_CENTER ->", s, "" if s in (200, 201) else first_error(p))


def ensure_detail():
    detail_id = get_detail_id()
    if detail_id:
        print(f"gameCenterDetail exists: {detail_id}")
        return detail_id
    s, p = req("POST", "/v1/gameCenterDetails", {
        "data": {
            "type": "gameCenterDetails",
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }
    })
    if s in (200, 201):
        print("created gameCenterDetail:", p["data"]["id"])
        return p["data"]["id"]
    print("create gameCenterDetail FAILED:", first_error(p)); sys.exit(1)


def create_leaderboards(detail_id, existing):
    for vid, name, suffix in LEADERBOARDS:
        if vid in existing:
            print(f"  = leaderboard exists: {vid}")
            continue
        s, p = req("POST", "/v1/gameCenterLeaderboards", {
            "data": {
                "type": "gameCenterLeaderboards",
                "attributes": {
                    "referenceName": name,
                    "vendorIdentifier": vid,
                    "defaultFormatter": "INTEGER",
                    "submissionType": "BEST_SCORE",
                    "scoreSortType": "DESC",
                },
                "relationships": {
                    "gameCenterDetail": {"data": {"type": "gameCenterDetails", "id": detail_id}}
                },
            }
        })
        if s not in (200, 201):
            print(f"  ! create leaderboard {vid} FAILED:", first_error(p)); continue
        lb_id = p["data"]["id"]
        s2, p2 = req("POST", "/v1/gameCenterLeaderboardLocalizations", {
            "data": {
                "type": "gameCenterLeaderboardLocalizations",
                "attributes": {"locale": "en-US", "name": name, "formatterSuffix": suffix,
                               "formatterSuffixSingular": suffix},
                "relationships": {
                    "gameCenterLeaderboard": {"data": {"type": "gameCenterLeaderboards", "id": lb_id}}
                },
            }
        })
        print(f"  + leaderboard {vid} ({lb_id}) loc->{s2}", "" if s2 in (200, 201) else first_error(p2))


def create_achievements(detail_id, existing):
    for vid, name, points, desc in ACHIEVEMENTS:
        if vid in existing:
            print(f"  = achievement exists: {vid}")
            continue
        s, p = req("POST", "/v1/gameCenterAchievements", {
            "data": {
                "type": "gameCenterAchievements",
                "attributes": {
                    "referenceName": name,
                    "vendorIdentifier": vid,
                    "points": points,
                    "showBeforeEarned": True,
                    "repeatable": False,
                },
                "relationships": {
                    "gameCenterDetail": {"data": {"type": "gameCenterDetails", "id": detail_id}}
                },
            }
        })
        if s not in (200, 201):
            print(f"  ! create achievement {vid} FAILED:", first_error(p)); continue
        ach_id = p["data"]["id"]
        s2, p2 = req("POST", "/v1/gameCenterAchievementLocalizations", {
            "data": {
                "type": "gameCenterAchievementLocalizations",
                "attributes": {
                    "locale": "en-US",
                    "name": name,
                    "beforeEarnedDescription": desc,
                    "afterEarnedDescription": desc,
                },
                "relationships": {
                    "gameCenterAchievement": {"data": {"type": "gameCenterAchievements", "id": ach_id}}
                },
            }
        })
        print(f"  + achievement {vid} ({ach_id}) loc->{s2}", "" if s2 in (200, 201) else first_error(p2))


def ach_localization_id(ach_id):
    s, p = req("GET", f"/v1/gameCenterAchievements/{ach_id}/localizations?limit=10")
    if s != 200:
        return None
    for d in p.get("data", []):
        if d["attributes"].get("locale") == "en-US":
            return d["id"]
    return None


def existing_image(loc_id):
    s, p = req("GET", f"/v1/gameCenterAchievementLocalizations/{loc_id}/gameCenterAchievementImage")
    if s == 200 and p.get("data"):
        d = p["data"]
        return d["id"], d["attributes"].get("assetDeliveryState", {}).get("state")
    return None, None


def raw_put(op, chunk):
    r = urllib.request.Request(op["url"], data=chunk, method=op.get("method", "PUT"))
    for h in op.get("requestHeaders", []):
        r.add_header(h["name"], h["value"])
    with urllib.request.urlopen(r) as resp:
        return resp.status


def upload_images(detail_id, art_dir):
    boards, achs = list_existing(detail_id)
    for vid, name, points, desc in ACHIEVEMENTS:
        ach_id = achs.get(vid)
        if not ach_id:
            print(f"  ! no achievement record for {vid}"); continue
        loc_id = ach_localization_id(ach_id)
        if not loc_id:
            print(f"  ! no en-US localization for {vid}"); continue
        img_id, state = existing_image(loc_id)
        if img_id and state in ("COMPLETE", "UPLOAD_COMPLETE"):
            print(f"  = image complete: {vid}"); continue
        if img_id:
            req("DELETE", f"/v1/gameCenterAchievementImages/{img_id}", expect=(204,))
        path = os.path.join(art_dir, f"{vid}.png")
        if not os.path.exists(path):
            print(f"  ! missing art {path}"); continue
        data = open(path, "rb").read()
        s, p = req("POST", "/v1/gameCenterAchievementImages", {
            "data": {
                "type": "gameCenterAchievementImages",
                "attributes": {"fileName": f"{vid}.png", "fileSize": len(data)},
                "relationships": {
                    "gameCenterAchievementLocalization": {
                        "data": {"type": "gameCenterAchievementLocalizations", "id": loc_id}
                    }
                },
            }
        })
        if s not in (200, 201):
            print(f"  ! reserve image {vid} FAILED:", first_error(p)); continue
        img_id = p["data"]["id"]
        ops = p["data"]["attributes"]["uploadOperations"]
        try:
            for op in ops:
                raw_put(op, data[op["offset"]:op["offset"] + op["length"]])
        except urllib.error.HTTPError as e:
            print(f"  ! upload {vid} FAILED: {e.code} {e.read()[:200]}"); continue
        s2, p2 = req("PATCH", f"/v1/gameCenterAchievementImages/{img_id}", {
            "data": {
                "type": "gameCenterAchievementImages",
                "id": img_id,
                "attributes": {"uploaded": True},
            }
        })
        st = p2.get("data", {}).get("attributes", {}).get("assetDeliveryState", {}) if s2 == 200 else {}
        print(f"  + image {vid} ({img_id}) commit->{s2} {st.get('state', '')}",
              "" if s2 in (200, 201) else first_error(p2))


def main():
    phase = sys.argv[1] if len(sys.argv) > 1 else "discover"
    if phase == "discover":
        discover(); return
    if phase in ("capability", "all"):
        enable_capability()
    if phase in ("detail", "leaderboards", "achievements", "all"):
        detail_id = ensure_detail()
        boards, achs = list_existing(detail_id)
        if phase in ("leaderboards", "all"):
            print("Leaderboards:"); create_leaderboards(detail_id, boards)
        if phase in ("achievements", "all"):
            print("Achievements:"); create_achievements(detail_id, achs)
    if phase == "images":
        detail_id = ensure_detail()
        art_dir = sys.argv[2] if len(sys.argv) > 2 else "build/gc-art"
        print("Achievement images:"); upload_images(detail_id, art_dir)


if __name__ == "__main__":
    main()
