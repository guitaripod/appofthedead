---
name: revenue-ops
description: Weekly App of the Dead revenue ritual — pull metrics, append docs/metrics.csv, evaluate the 30/60/90 gates from the playbook, and output one decision. Use when asked to "run revenue ops", "check the numbers", or on a weekly cadence.
---

# Revenue ops ritual

App Store id `6746733380`. Run the whole ritual; end with a gate verdict, not raw numbers.

## 1. Pull metrics

Ratings + listing state (keyless, per storefront — at minimum us, gb, de, fi):

```bash
curl -s "https://itunes.apple.com/lookup?id=6746733380&country=us" | python3 -c "import json,sys; r=json.load(sys.stdin)['results'][0]; print(r['averageUserRating'], r['userRatingCount'], r['version'], r['price'])"
```

ASC sales/downloads (API key `DSS2FFU68G`, issuer in `~/.config/midgar/credentials.env`, p8 in `~/.appstoreconnect/private_keys/`). Mint an ES256 JWT (pyjwt) and call:

- `GET /v1/salesReports?filter[frequency]=WEEKLY&filter[reportType]=SALES&filter[reportSubType]=SUMMARY&filter[vendorNumber]=93803823&filter[reportDate]=<YYYY-MM-DD>` — gzip TSV; units by SKU separate app downloads from path/premium/ultimate units and proceeds.
- VENDOR number: 93803823 (account-level, all Midgar apps).

Subscription funnel (trial starts, trial→paid, MRR): `GET https://api.revenuecat.com/v2/projects/proj7793585f/metrics/overview` with Bearer `$RC_SECRET_AOTD` from `~/.config/midgar/credentials.env`.

Review texts (reply-within-48h duty):

```bash
curl -s "https://itunes.apple.com/us/rss/customerreviews/page=1/id=6746733380/sortby=mostrecent/json"
```

## 2. Record

Append one row to `docs/metrics.csv` (create with header if absent):

```
date,us_ratings,us_avg,ww_ratings,downloads_wk,trial_starts_wk,sub_units_wk,path_units_wk,ultimate_units_wk,proceeds_wk,notes
```

Commit it.

## 3. Evaluate gates (full table in docs/store-playbook.md §4)

- Day 30 post-1.1.0: ≥300 downloads AND ≥5 trial starts → hold; else re-cut screenshots 1–3 / PPO-test subtitle. <50 downloads = ASO problem first.
- Day 60: trial→paid ≥30% → ship experiment SKUs; <20% → lengthen trial to 14 days before touching prices.
- Day 90: proceeds ≥ $100/mo → start the experiment ladder (localization > trial structure > plan duration > price > cosmetics). **Never ship features to fix a funnel.**

## 4. Output

One short report: the new row, week-over-week deltas, which gate window is active, the single recommended action, and any unanswered reviews (draft replies, ask before posting).
