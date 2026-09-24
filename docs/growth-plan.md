# App of the Dead: Growth Plan (2026-09-24)

Written from a 10-agent diagnosis (funnel code, live store state, ASO/competitors, channels, monetization) with three adversarial reviewers. Every figure below was then re-checked by hand. Two workflow findings were wrong and are dropped (see "Rejected").

## 1. Diagnosis: the problem is impressions

| Stage (App Store Discovery & Engagement report) | Aug 2026 | Week of 2026-09-07 |
|---|---|---|
| Impressions | 2,494 (2,369 search, 125 browse) | 550 |
| Product page views | 212 (8.5%) | 45 (8.2%) |
| "Get" taps | 41 (19% of views) | 9 (20%) |

- Page-view→install conversion is normal and stable. The app is simply shown to ~80 people a day, almost all from search.
- Lifetime: 67 first-time downloads since 2026-05-28 (~1/day in September). 0 ratings, 0 reviews, 0 IAP units, 0 trials, 0 subscriptions, $0 proceeds. RevenueCat 28d: 17 new, 22 active, so only ~5 users return.
- **Search:** top-50 only for "world religions" (US #8), "religions", "afterlife" (US #16) and "religion app" (#34). The app is absent for mythology, greek/norse/egyptian mythology, gods, pantheon, buddhism and hinduism. The top apps on those terms have only 0–82 ratings, so they are winnable. The likely gates are 0 ratings and a keyword field that is 21% redundant (it repeats "religions" and "mythology" from the name and subtitle).
- **Name collision:** on the US store, a search for "app of the dead" ranks a 9-rating ghost-hunting app above us, followed by Walking Dead and Into the Dead. On the DE store we don't appear at all among 48 zombie titles. The brand reads as horror.
- **Unclaimed niche:** "talk to the gods" returns only Jesus-chat apps. Text With Jesus has 3,863 ratings, which proves the demand. No app offers chat across multiple pantheons, which is exactly what the Oracle does. Yet the en-US name, subtitle and keywords never mention it.
- **Ratings:** `ReviewPrompt` needs 3 completed lessons. With ~5 returning users a month, almost nobody reaches it.

### Revenue math (live prices)
Live US prices (verified via asc 2026-09-24) are **annual $19.99 (7-day trial), monthly $2.99, lifetime $89.99, paths $3.99, Oracle Wisdom $9.99**. §2 of the store playbook still says $39.99/$9.99, which is stale. The hosted Terms page (midgarcorp.cc/appofthedead/terms) says $19.99/$2.99 and is correct.

Education benchmarks: download→trial 6.5%, trial→paid 37%, so ~2.4% of downloads become paid. An annual subscription nets $16.99.
- Current ~30 downloads a month ≈ 0.7 paid a month ≈ $12/mo added per month. Zero so far is within noise (P ≈ 20%).
- $100/mo net needs ~245 downloads a month (~8/day). $1,000/mo needs ~80/day.
- **Revenue is purely a function of volume. No pricing or paywall change is measurable at this traffic.**

## 2. Ranked actions

| # | Action | Owner | Hours | Cash | Deadline |
|---|---|---|---|---|---|
| A1 | en-US promotional text (was empty; the other 9 locales had one) | done 2026-09-24 | – | $0 | – |
| A2 | ASO release 1.4.7: keywords + rating-prompt trigger + share link (details below) | claude, Marcus approves | 4 | $0 | submit by 2026-10-03 |
| A3 | Keep the name (decided 2026-09-24); move the subtitle to "talk to the gods" (folds into A2 if approved) | **Marcus decides** | +1 | $0 | with A2 |
| A4 | In-app event "Journey to Mictlan" (Día de los Muertos) | claude builds, Marcus approves | 4 | $0 | submit by 2026-10-06 |
| A5 | Featuring nomination (`asc nominations create`) | claude drafts, Marcus approves | 1 | $0 | this week |
| A6 | Show HN + r/LocalLLaMA post: shipping Gemma 4 on-device in a consumer iOS app | Marcus posts | 3 | $0 | after A2 is live |
| A7 | Apple Search Ads exact-match test on mythology terms | **Marcus decides** | 1 | $100–150 | after A2 is live |
| A8 | Portfolio call: cap AOTD at ~10h this quarter unless the Day-30 gate clears | **Marcus decides** | – | – | now |

### A2: the ASO release (1.4.7)
Keywords, name and subtitle change only with a new version. 1.4.7 exists in ASC but **has no build**. The only valid build (202608170200) is the one live on 1.4.6, and a build can't move to another marketing version. So A2 needs a fresh binary with MARKETING_VERSION 1.4.7. This Mac is on beta macOS `26B5091g`, so build it with `buildvm`, never local `xcodebuild`.

1. **Keywords (en-US)**, if the name is kept (93/100):
   `quiz,afterlife,trivia,gods,pantheon,egyptian,norse,greek,buddhism,hinduism,deity,chat,ai,soul`
   This drops "religions" and "mythology" (already indexed from the name and subtitle) and adds quiz, afterlife, trivia, gods, chat and ai. The DE/FR/ES/IT locales already carry quiz and oracle terms, so en-US is currently the least optimized locale.
2. **Rating prompt:** fire after the **first** completed lesson with a score of 80% or more, instead of after 3 lessons. It stays once per version. Ratings are the search-ranking input we most lack, and Apple throttles the system prompt anyway.
3. **Share text:** `HomeViewController.sharePath` (line 353) and `BookReaderViewController.shareText` (line 1114) share text with no link. Append `https://apps.apple.com/app/id6746733380`.
4. **First screenshot** leads with an Oracle chat (for example Anubis answering "what happens when I die?"). Screenshots 2–5 keep the current order.
5. What's New lists everything since 1.4.6, translated into all 10 locales.

### A3: subtitle (Marcus's decision; the name stays)
- The name stays **"App of the Dead: Religions"**. A rename was rejected on 2026-09-24.
- Proposed subtitle: **"Mythology Quiz & Talk to Gods"** (29 chars), replacing "World Religions & Mythology". It keeps "Religions" (from the name) and "Mythology", and claims the empty "talk to gods" query.
- "world" moves into the keywords to keep the "world religions" ranking (US #8). The keywords become `afterlife,trivia,world,pantheon,egyptian,norse,greek,buddhism,hinduism,deity,theology,chat,ai,soul` (98/100).
- If the subtitle stays too, ship only the A2 keywords and re-check the ranking at Day 30.

### A4: in-app event
- Event: "Journey to Mictlan", a Challenge type running Oct 24 – Nov 2 with promotion from Oct 10. It uses existing content: the Aztec Mictlan path (first lesson is a free preview) plus Mictlantecuhtli in the Oracle, who is in no deity pack and so gets the 3 free consultations (`UserPurchaseExtensions.canConsultOracle`).
- Events are indexed in search and shown on the product page and in browse, so they add impressions without a build.
- Needs a 1920×1080 card, a 1080×1920 detail image, a name of 30 characters or fewer, a 50-character short description and a 120-character long description. The event must state that the full path is a purchase.
- It needs its own review, so submit by Oct 6.

### A5: featuring nomination
Pitch: on-device Gemma 4 god-chat (private, offline), 22 faiths, 10 languages, VoiceOver and Dynamic Type. Target the new-year window (editorial plans 8–12 weeks ahead). Halloween is realistically too late for featuring but not for the event.

## 2b. Status (2026-09-25)

- **A1** done 2026-09-24.
- **A2 + A3 + A4 submitted together**: review submission `bb861fe0-44ba-49e8-9ef5-ba55b1c12e63` has been WAITING_FOR_REVIEW since 2026-09-24 21:30 UTC. It contains:
  - version 1.4.7, build `202609250045` (buildvm, stable host `25F71`);
  - in-app event `6815839274`, "Journey to Mictlan": SPECIAL_EVENT, promoted from Oct 10, runs Oct 24 – Nov 2, available in 175 territories and 10 locales, deep link `appofthedead://path/aztec-mictlan`.
- **Listing changes in the submission**: the new en-US subtitle "Mythology Quiz & Talk to Gods", the A3 keyword set (with "world"), What's New in 10 locales, and an authentic Oracle chat as en-US screenshot #1. The chat text is Gemma 4 E2B output generated with thinking off, as the app runs it.
- **A5**: two nominations submitted.
  - `fe80c7e3` (APP_ENHANCEMENTS): on-device Oracle, publish from 2027-01-05.
  - `282b4685` (NEW_CONTENT): the Mictlan event, Oct 24 – Nov 2.
- **Fixed on the way**:
  - Oracle replies showed raw Markdown asterisks. They now render as formatted text.
  - The June stop-token "fix" (ee53051) replaced Gemma 4's real `<turn|>` token with a token that doesn't exist in Gemma 4's vocabulary. Reverted in 0504fb9.
  - AOTD had no file logger. It now writes `Library/Logs/aotd.log`.
  - The age-rating social-media answers were missing and blocked submission. Both are now set to false.
  - Copyright changed to "2025 Midgar Oy".
- **Open**:
  - A6: post `marketing/outreach-2026-10.md` (b)/(c) from Marcus's accounts once 1.4.7 is live.
  - A7: Search Ads spend is Marcus's call.
  - Run revenue-ops on 2026-10-24 against the Day-30 gate.

## 3. Rejected

- **"Fix wrong prices on the Terms page, then submit 1.4.7's pending build."** Wrong on both counts. The Terms page matches the live prices. Build 202608170200, which carries the legal-link fix (0855f96), is already live as 1.4.6. 1.4.7 is an empty shell with nothing in git since.
- **"Shared paywall-key bug in `LearningPathCoordinator`."** This is intentional. A user whose first lesson was a locked-path preview already saw the `.lockedPath` paywall, so the general one is suppressed.
- **Funnel instrumentation via AppLogger.** AppLogger writes to a file on the user's device, so the data never reaches us. At ~30 downloads a month, no instrumentation could reach significance anyway.
- **Any pricing, paywall or SKU change** (re-arming the paywall, wiring the Oracle Wisdom SKU, a cheaper lifetime, A/B tests). None of it can be measured at this volume. Revisit at ≥250 downloads a month.
- **Full lesson and Oracle content localization.** It's large, and non-English storefronts supply ~40% of a base of 67 downloads (JP, FR, KR, TW and DE do draw real impressions). Revisit if the Day-60 gate clears.
- **A 30-day short-form video series.** It would cost 12h+ against a zero-follower cold start.

## 4. Gates

| Checkpoint | Target | If missed |
|---|---|---|
| Day 30 (2026-10-24) | A2 live; ≥ 50 downloads in 30 days; top-50 US for "mythology" or "gods"; ≥ 1 rating | Ship the A3 subtitle if it was deferred. If it already shipped, stop investing and hold AOTD in maintenance |
| Day 60 (2026-11-23) | ≥ 100 downloads in 30 days; first trial or IAP | Run A7 to tell apart "keywords don't rank" from "traffic doesn't convert" |
| Day 90 (2026-12-23) | proceeds ≥ $100/mo (≈ 8 downloads/day) | Explicit continue-or-redirect call against Master of Flags (189 dl/90d), Solar Beam (193) and Flaccy (239), which already out-pull AOTD (58) by 3–4x |
