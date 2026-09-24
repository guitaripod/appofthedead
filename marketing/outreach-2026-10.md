# Outreach drafts — 2026-10 (1.4.7 launch window)

Status (2026-09-25): (a) the Oracle featuring nomination was SUBMITTED to Apple as "Talk with the gods, privately on-device" (nomination `fe80c7e3-a705-48a1-8215-960e3137d01e`, APP_ENHANCEMENTS, publish from 2027-01-05) with a tightened description; a second NEW_CONTENT nomination for the Journey to Mictlan in-app event (`6815839274`, Oct 24 - Nov 2) is filed with the 1.4.7 submission. The text in section (a) below is the original draft, kept for reference. (b) and (c) are drafts for Marcus to post from his own accounts. The stop-token paragraphs were corrected on 2026-09-25: the "typo" was a misreading and has been reverted in 0504fb9.

House rules applied throughout: no emoji, no hype words ("revolutionary", "game-changing", etc.), no fake urgency, honest about what the app is (small, new, free-in-parts, paid-in-parts).

---

## (a) App Store featuring nomination

**Target window:** early January 2027 (new-year / "learn something new" resolutions — Apple's editorial team plans 8–12 weeks out, so this needs to go in well before then). The Día de los Muertos event (Oct 24–Nov 2, 2026) will already be over by the publish date, so it's cited as *proof the feature works and gets used*, not as a live hook.

**Nomination type:** `APP_ENHANCEMENTS` — the Oracle (on-device Gemma 4 chat with deities) is the enhancement being nominated, not the app's original launch, and there's no new in-app content tied to the publish date itself.

**Fields:**

| Field | Value |
|---|---|
| App | 6746733380 |
| Name | On-Device Oracle: AI Chat With Gods, Offline (44 chars) |
| Type | APP_ENHANCEMENTS |
| Publish start | 2027-01-05 (Tue), 08:00 UTC |
| Publish end | not set — this is a standing capability, not a time-boxed promo |
| Device families | IPHONE only (app is iPhone-only per CLAUDE.md target) |
| Locales | en-US, de-DE, fr-FR, es-ES, it, pt-BR, ja, ko, zh-Hans, zh-Hant — all 10 storefronts the UI is localized into |
| Submitted | false — this creates a draft nomination for Marcus to review and submit himself |

**Description** (no hype words, factual, leads with the on-device angle as instructed):

> App of the Dead teaches afterlife beliefs across 22 traditions — Egyptian, Norse, Greek, Aztec, Buddhist, and more — through Duolingo-style lessons and quizzes. Its Oracle feature lets a learner talk directly with a tradition's deity — Anubis, Odin, Mictlantecuhtli, and others — powered by Google's Gemma 4 (E2B, 4-bit) running fully on-device via mlx-swift. The model downloads once; every conversation after runs offline, with nothing sent to a server. The app is available in 10 languages (English, German, French, Spanish, Italian, Brazilian Portuguese, Japanese, Korean, Simplified and Traditional Chinese), supports VoiceOver and Dynamic Type, and includes Game Center achievements and leaderboards. From October 24 to November 2, 2026, the normally paid Aztec Mictlan path opened to every user for Día de los Muertos, paired with the Mictlantecuhtli Oracle persona — a real, played example of the on-device model teaching accurate mythology rather than a tech demo.

**Internal notes** (`--notes`, editorial context, not shown publicly):

> Solo-developer iOS app. The Oracle is a real shipped feature (live since version 1.4.0, hardened through two follow-up releases), not a preview — happy to provide a demo build or TestFlight link on request. Second attached angle: full on-device privacy (no server round-trip for any Oracle conversation) plus 10-language accessibility (VoiceOver, Dynamic Type) in a solo-developer app.

**Exact command** (Marcus runs this himself; `asc nominations create --help` fields confirmed live 2026-09-24):

```bash
asc nominations create \
  --app "6746733380" \
  --name "On-Device Oracle: AI Chat With Gods, Offline" \
  --type APP_ENHANCEMENTS \
  --description "App of the Dead teaches afterlife beliefs across 22 traditions — Egyptian, Norse, Greek, Aztec, Buddhist, and more — through Duolingo-style lessons and quizzes. Its Oracle feature lets a learner talk directly with a tradition's deity — Anubis, Odin, Mictlantecuhtli, and others — powered by Google's Gemma 4 (E2B, 4-bit) running fully on-device via mlx-swift. The model downloads once; every conversation after runs offline, with nothing sent to a server. The app is available in 10 languages (English, German, French, Spanish, Italian, Brazilian Portuguese, Japanese, Korean, Simplified and Traditional Chinese), supports VoiceOver and Dynamic Type, and includes Game Center achievements and leaderboards. From October 24 to November 2, 2026, the normally paid Aztec Mictlan path opened to every user for Día de los Muertos, paired with the Mictlantecuhtli Oracle persona — a real, played example of the on-device model teaching accurate mythology rather than a tech demo." \
  --submitted=false \
  --publish-start-date "2027-01-05T08:00:00Z" \
  --device-families IPHONE \
  --locales en-US,de-DE,fr-FR,es-ES,it,pt-BR,ja,ko,zh-Hans,zh-Hant \
  --notes "Solo-developer iOS app. The Oracle is a real shipped feature (live since version 1.4.0, hardened through two follow-up releases), not a preview — happy to provide a demo build or TestFlight link on request. Second attached angle: full on-device privacy (no server round-trip for any Oracle conversation) plus 10-language accessibility (VoiceOver, Dynamic Type) in a solo-developer app." \
  --output json --pretty
```

Not filled in: `--supplemental-materials-uris` and `--in-app-events`. There's no hosted screenshot/video asset to link yet (the Oracle-chat screenshot refresh is still pending, per A2 of the growth plan), and the Día de los Muertos event will have ended by the publish window so it isn't an active in-app event to attach. If a supporting screenshot or short clip of an Oracle conversation gets hosted before submission, add it via `--supplemental-materials-uris` (comma-separated URLs).

---

## (b) Show HN

**Title** (75/80 chars):

> Show HN: Shipping Gemma 4 (E2B) on-device in a consumer iOS app (mlx-swift)

**Body:**

> I ship a small iOS app (App of the Dead — a Duolingo-style app for learning how different cultures picture the afterlife, 22 traditions, UIKit/GRDB) with a feature called the Oracle: you can chat with a tradition's deity. Since 1.4.0 that chat runs Google's Gemma 4 (E2B, 4-bit) entirely on-device via [mlx-swift](https://github.com/ml-explore/mlx-swift) / mlx-swift-lm — no server, no API key, works offline after the first download. Writing this up because the model-serving side turned out to be most of the engineering, and most of it was invisible plumbing rather than anything ML-specific.
>
> **Model choice / device tiering.** I keep a small catalog of candidate models, each with a minimum physical-RAM gate, ordered heaviest-first: Gemma 4 E2B (4-bit, ~3.6 GB download, needs ≥7 GB RAM) falling back to Gemma 3 4B-text (4-bit, ~2.5 GB, no RAM floor — it's the one every device can run) if the device can't take E2B or E2B fails to load. I also built a Gemma 4 E4B tier but shelved it — it's in the catalog code but not wired into the active fallback chain, since E2B was already the ceiling worth shipping to most of the install base. I tried a Qwen variant early on and dropped it — not coherent enough for open-ended in-character chat, whereas Gemma 4 E2B (Apache-2.0) held up.
>
> **Download.** The weights are 3.6 GB, too big to bundle and too slow to fetch to make someone wait in the foreground. That's a background `URLSession` (`isDiscretionary = false`, `waitsForConnectivity = true`, 7-day resource timeout) so the download survives app suspension and keeps going overnight. It pulls a commit-pinned file manifest from the HuggingFace API (`/api/models/{repo}` for the commit SHA, then `/tree/{sha}?recursive=true&expand=true` for exact sizes and the LFS SHA-256 oid per file), resumes per-file by comparing on-disk size against the manifest, and after every file lands it streams a SHA-256 over 4 MB chunks and checks it against the LFS oid before touching the `.safetensors` header (reads the little-endian 8-byte header length, sanity-checks it's `> 0` and fits inside the file) — cheap enough to catch a truncated or corrupted download before it ever reaches MLX. Storage lives in `Application Support`, marked `isExcludedFromBackup`, and a directory only counts as "ready" once a `.verified` marker file gets written after the full check passes.
>
> **Load-time sanity probe.** A model that downloads and quantizes cleanly can still misbehave on-device — we had a specific case of early Gemma 4 PLE-quant output degrading into unprintable garbage. So after `ModelContainer` load succeeds, I run a cheap probe: ask it to "Reply with exactly: OK", cap it at 24 tokens, and check the output is non-empty with a >80% printable-character ratio. Fail the probe and the loader throws, the model manager drops to the next entry in the fallback chain, and the failure gets logged — so a device that can't run E2B cleanly falls through to Gemma 3 instead of shipping a broken Oracle.
>
> **The stop-token false alarm.** mlx-swift-lm's registry lists Gemma 4's extra stop token as `<turn|>`, where its Gemma 3 entries use `<end_of_turn>`. I read that as a typo and "fixed" it. It wasn't one: Gemma 4 renamed its turn delimiters to `<|turn>` / `<turn|>` (id 106), and `<end_of_turn>` doesn't exist in its vocabulary at all. Generation had been stopping correctly the whole time because `generation_config.json`'s `eos_token_id` of `[1, 106, 50]` also feeds the stop set. I reverted the override. Lesson: read the tokenizer's `added_tokens` before trusting pattern-matching across model generations.
>
> **Token budget.** Generation ceilings started at 800 tokens for conversation / 400 for cached lesson-keyword explanations, which was cutting the model off mid-sentence on longer in-character answers. Gemma's context window is 32K, so there was no real reason to be that conservative — bumped to 2048 / 1024. These are safety ceilings, not targets: an instruction-tuned model hits its own end-of-turn token and stops on its own for the overwhelming majority of answers.
>
> **Memory.** Even the 4-bit E2B model plus KV cache pushes against the default iOS per-app memory ceiling on some devices, so the app carries the `com.apple.developer.kernel.increased-memory-limit` entitlement. MLX's GPU cache is bounded explicitly too — `512 MB` while a model is loaded, cleared to `0` on unload/memory pressure — since MLX doesn't otherwise know it's sharing a phone with the rest of the app.
>
> **Framework churn.** mlx-swift-lm moved its model-declaration mechanism between versions while I was building this (to a macro-based approach), which meant pinning to 3.31.3 and adding `-skipMacroValidation` in CI to get a clean, non-interactive build — worth flagging since anyone pinning to a specific mlx-swift-lm version for CI will hit the same wall.
>
> None of this is exotic ML work — it's the download/verify/load/fallback/memory plumbing that any team shipping a multi-GB on-device model on iOS is going to end up writing themselves, so figured it was worth a writeup rather than assuming it's obvious. Happy to go deeper on any of it.
>
> App: https://apps.apple.com/app/id6746733380

---

## (c) r/LocalLLaMA

Checked the sub's current self-promotion norms (2026-09-24): self-promo is tolerated when it's framed as a genuine technical contribution rather than a pitch, should stay well under ~10% of a poster's overall activity there, affiliation must be disclosed plainly rather than left implicit, no bare product links in the title, and posts that read as an ad over a lesson get removed. Adapted from the Show HN body below accordingly: title carries no link, the app is named once with an explicit "I'm the developer" disclosure rather than repeated, and the framing leads with the reusable engineering lesson (the Gemma 4 turn tokens, the fallback/sanity-probe pattern) rather than the app itself. Suggest posting with whatever flair the sub currently uses for "Resources"/"Tutorial" — confirm the live flair list at post time, it wasn't checked here.

**Title:**

> Gemma 4 (E2B) on-device on iOS via mlx-swift: a stop-token false alarm, the sanity-probe fallback, and what it actually takes to ship a multi-GB local model in a consumer app

**Body:**

> Disclosure up front: I'm the solo developer of the app this came out of (App of the Dead, an iOS app for learning afterlife beliefs across 22 traditions) — mentioning it once for context, not here to pitch it. What I actually want to share is the on-device serving stack underneath its "Oracle" chat feature, since I hit a few issues along the way that I couldn't find written up anywhere and figure others hitting mlx-swift-lm will run into the same ones.
>
> Stack: Gemma 4 E2B, 4-bit, via mlx-swift / mlx-swift-lm, running fully offline after a one-time ~3.6 GB download. No server component for inference at all.
>
> **1. Gemma 4's end-of-turn token is `<turn|>`, not `<end_of_turn>`.** mlx-swift-lm's registry uses `<turn|>` for Gemma 4 and `<end_of_turn>` for Gemma 3. That looks like a typo and isn't: Gemma 4 renamed its turn delimiters (`<|turn>` / `<turn|>`, id 106), and `<end_of_turn>` is absent from its vocabulary. I "fixed" it anyway, then reverted after checking `tokenizer.json`. Stopping was never broken because `generation_config.json`'s `eos_token_id` `[1, 106, 50]` is merged into the stop set. If you override `extraEOSTokens` for Gemma 4, check the tokenizer's `added_tokens` first.
>
> **2. A "loads fine" model can still be silently broken — add a post-load sanity probe.** I hit a case where an early Gemma 4 4-bit quant loaded cleanly through `ModelContainer` but degraded into unprintable-garbage output. Cheap fix: right after load, generate a short deterministic response (`temperature: 0`, ~24 tokens, prompt it to reply with an exact fixed string) and check the output is non-empty with a high printable-character ratio. If it fails, don't show the model to the user — fall back.
>
> **3. Which makes a device-tiered fallback chain worth having from day one**, not bolted on later. Catalog of candidate models ordered heaviest→lightest, each gated on a minimum physical-RAM threshold; pick the heaviest the device clears, and on a load failure or a failed sanity probe, descend to the next one down rather than failing the feature outright. Concretely: Gemma 4 E2B (needs ≥7 GB RAM) falling back to Gemma 3 4B-text (no RAM floor) for the rest. I also had a Gemma 4 E4B tier ready but didn't wire it into the live chain — not worth the download size for the marginal quality gain at this app's scale.
>
> **4. The download and verify path matters more than the inference code.** 3.6 GB doesn't fit in a foreground download without annoying people, so it's a background `URLSession` (`isDiscretionary = false`, `waitsForConnectivity = true`) that survives app suspension, against a commit-pinned HuggingFace manifest (resolve the commit SHA, then pull the recursive tree for exact sizes + the LFS SHA-256 oid per file) so a mid-download HF repo update can't hand you mismatched files. Every file gets its SHA-256 checked against the LFS oid after it lands, plus a `.safetensors` header sanity check (valid little-endian header length that actually fits inside the file), before a `.verified` marker makes the snapshot eligible to load.
>
> **5. Memory.** Even a 4-bit E2B model plus KV cache pushes the default iOS per-process memory ceiling on some devices — needed the `com.apple.developer.kernel.increased-memory-limit` entitlement, plus bounding MLX's own GPU cache explicitly (I cap it at 512 MB while a model's loaded, drop it to 0 on unload/memory pressure) since MLX doesn't know on its own that it's sharing RAM with the rest of a consumer app.
>
> One framework note for anyone pinning versions: mlx-swift-lm changed how models get declared (moved to a macro-based approach) between versions I was tracking, so I'm pinned to 3.31.3 with `-skipMacroValidation` added in CI to keep builds non-interactive.
>
> None of this is novel ML — it's the download/verify/load/fallback/memory plumbing every team shipping a multi-GB local model on iOS ends up building. Sharing in case it saves someone the same debugging session, especially #1 and #2, which cost me the most time to track down. Happy to go into any part of it further.

---

## What I could not do

- Character limits for the nomination fields (not printed by the CLI's `--help`) are confirmed via Apple's own Nominations template reference (developer.apple.com/help/app-store-connect/reference/nominations/nominations-template): name 60 characters, description 1,000 characters, notes ("Helpful Details") 500 characters. Current draft: name 44/60, description 973/1,000, notes 385/500 — all within limits, description close enough to the cap that any future edit should recount it.
- Did not fetch Reddit's own rules page directly (`reddit.com` is blocked to this session's fetch tool); the r/LocalLLaMA self-promotion guidance above is synthesized from third-party trackers of that subreddit's norms (Intoru, LaunchWake) rather than the subreddit's own wiki text. Worth a manual skim of the live sidebar/wiki before posting in case the mods have changed anything since.
- Did not check the subreddit's current flair options (need to be logged into Reddit to see them) — flagged as a manual step above.
- No screenshots, event artwork, or hosted media exist yet for `--supplemental-materials-uris` on the nomination — that depends on the in-progress 1.4.7 work (screenshot refresh leading with an Oracle chat, per A2 of the growth plan).
