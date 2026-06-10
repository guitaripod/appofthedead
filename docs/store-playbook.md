# App of the Dead — Store & Revenue Playbook (1.1.0)

App ID `6746733380` · bundle `com.marcusziade.aotd` · subscription group "Premium" (22148452) · RC project `proj7793585f` (`RC_SECRET_AOTD` in the vault; `ultimate` = `entlb89a419762`).

Written 2026-06-10 from primary research (RevenueCat *State of Subscription Apps 2026*, Adapty *State of In-App Subscriptions 2026*, Superwall, live store teardowns of the faith/education comp set, live ASC audit, 87 findings with 24 adversarially verified). Every decision cites its evidence.

## 0. Baseline (2026-06-10)

Live 1.0.2 (metadata remaster shipped 2026-06-07): free download, 26 approved non-consumables (21 paths at $2.99, 3 deity packs at $1.99, Oracle Wisdom $9.99, Ultimate lifetime $19.99), zero subscriptions, zero trials, zero ratings, zero reviews. Judaism path free forever. Oracle: 3 free consultations per deity (on-device MLX — zero marginal cost). Vendor number: 93803823 (account-level, shared by all Midgar apps).

**Live 1.0.2 likely crashes at launch on iOS 26.5 devices**: RevenueCat 5.29.0 reads `Bundle.main.appStoreReceiptURL` on a background queue during configure (purchases-ios#6886, the exact bug that got DreamEater 1.3.0 rejected). 1.1.0 ships RC 5.78.0 + main-thread pre-warm.

## 1. Market facts that drive the design

- Education sustains the highest annual price of any category: median $9.99/mo, $44.99/yr; 59–66% of education subs sold are annual (RevenueCat SOSA 2026).
- The faith-vertical comp set clusters at $9.99/mo, $35–70/yr, 7-day trial: Ascend $9.99/mo + $49.99/yr; Hallow $9.99/mo + $69.99/yr; Bible Chat $39.99–59.99/yr + $29.99 one-time (live listings, 2026-06-10).
- Trials: 5–9 days converts 37.4% median trial→paid vs 25.5% for ≤4 days; education trial users generate +50.4% 12-month LTV vs direct buyers (SOSA 2026; Adapty education, Apr 2026).
- Onboarding placement: most apps earn 60–80% of subscription revenue from the onboarding paywall; ~82% of trial starts happen Day 0. Education is also the slowest-deciding category (23.5% of trial starts come Day 31+) — keep re-entry paywalls alive (Adapty SOIS 2026).
- 3 plan options convert 44% better than 2; ~82% of purchasers buy the pre-selected plan (Superwall, 32M+ interactions).
- Apple mass-rejects trial-toggle paywalls under 3.1.2 since Jan 2026. Compliant pattern: trial badged on one plan + Blinkist timeline (+23% trial starts, −55% billing complaints).
- One-time purchases grew to 17% of education revenue; hybrid buyers are 7% of buyers but 25% of revenue. Lifetime guidance: price at 2x+ annual, never below it (Adapty; RevenueCat hybrid guides).
- Education annual renewal is ~24% (near-worst of any category) — LTV ≈ 1.24x annual price; lifetime below that number converts retainers into a cheap one-shot (RevenueCat renewal analysis).
- Soft paywalls suit education: hard paywalls win on D60 RPI but the median LTV edge is only ~21%, and education/productivity do better dismissable (Adapty 2026, corrected figures).

## 2. The 1.1.0 monetization design (decision → evidence)

| # | Decision | Evidence |
|---|---|---|
| 1 | Add subscription group "Premium": annual `com.appofthedead.premium.annual` **$39.99/yr** + monthly `com.appofthedead.premium.monthly` **$9.99/mo** | Category medians ($9.99/$44.99) and the entire faith comp set; $39.99 undercuts Ascend/Hallow annuals while staying in the credible band. The old internal plan ($14.99/yr, $3.99/mo) was 2.5–4x below verified norms |
| 2 | 7-day free trial (intro offer) on **annual only**; annual pre-selected | 5–9d trial sweet spot (37.4% trial→paid); trial-on-one-plan is the post-toggle-ban compliant steering pattern; 82% buy the default |
| 3 | Ultimate Enlightenment (lifetime) $19.99 → **$89.99**, repositioned from default-buy to anchor | At $19.99 lifetime sat *below* one year of comp-set annual — an LTV trap. $89.99 ≈ 2.25x annual per lifetime guidance; new buyers self-select into the trial-annual instead. Existing owners untouched (non-consumable, grandfathered automatically) |
| 4 | Path IAPs $2.99 → **$3.99** | Research band $3.99–4.99; 21 × $3.99 ≈ $84 keeps all-access strictly better value; $1.99–2.99 anchored against the $1.99 utility competitor |
| 5 | Deity packs stay $1.99; Oracle Wisdom stays $9.99 but is **demoted off the paywall** | Hybrid a-la-carte complements subs (25% of revenue from hybrid buyers); a second "unlimited oracle" SKU next to Premium split the decision and halved the sub funnel |
| 6 | Paywall rebuilt: 3 selectable plan cards (annual default w/ "7 DAYS FREE" badge), single CTA, Blinkist trial timeline, "✓ No payment due now", a-la-carte as subordinate text link | 3 options +44%; timeline +23% trial starts −55% complaints; "no payment due now" ~20% lift floor |
| 7 | Day-0 placement: paywall once after the **first completed lesson** (value moment), dismissible; locked-path and oracle-limit triggers stay | Onboarding paywalls = 60–80% of sub revenue, ~82% of trial starts Day 0; soft gate for education; path-specific headline +10–20% |
| 8 | Day-5 trial reminder local notification (promised in the timeline UI) | Blinkist honest-paywall pattern; the reminder is the complaint-mitigation, not optional polish |
| 9 | All-access derived from `entitlements["ultimate"]` OR active premium subscription OR ultimate non-sub record (`StoreManager.grantsAllAccess`) | No RevenueCat v2 secret key on this machine → new subs can't be dashboard-mapped to entitlements yet; CustomerInfo-based fallback keeps access correct regardless |
| 10 | RC SDK 5.29.0 → 5.78.0 + `appStoreReceiptURL` main-thread pre-warm | purchases-ios#6886 launch crash on iOS 26.5 devices (DreamEater rejection 2026-06-10) |

### 2b. Paywall compliance checklist (3.1.2, Jan–Feb 2026 enforcement wave)

- Billed price + full term dominant on every card ("$39.99/year", "$9.99/month", "$89.99 once"); per-month math subordinate.
- Trial copy sourced from `storeProduct.introductoryDiscount` via `StoreManager.fetchPremiumPlans` — never hardcoded; eligibility `.unknown` still shows trial terms (App Review sandbox).
- CTA switches with selection: "Start My 7-Day Free Trial" only on trial-bearing plan; otherwise "Subscribe"/"Unlock Lifetime".
- Disclosure line under CTA states price, term, auto-renewal, cancellation for the selected plan.
- Restore Purchases + tappable Terms of Use + Privacy Policy live on the paywall (`LegalLinks`).
- Paywall always dismissible; the next lesson is already waiting underneath the first-lesson paywall.

### 2c. Release sequencing (order is load-bearing)

1. Create subscription group + both subscriptions + localizations + prices in ASC.
2. Create the 7-day free-trial intro offer on the annual (all territories).
3. Apply one-time IAP price changes (ultimate $89.99, paths $3.99) — price changes on non-consumables don't need review and don't touch existing owners.
4. Subscriptions need review screenshots + notes; they ride the version submission the first time.
5. CI build (stable runner — this Mac is beta macOS, ITMS-90111) → upload → processingState VALID → attach to 1.1.0.
6. Metadata + screenshots (no price claims in screenshots), review notes, submit version + both subscriptions together.

## 3. Follow-ups requiring the human (priority order)

1. ~~RevenueCat v2 secret key~~ **DONE 2026-06-10**: `RC_SECRET_AOTD` in the vault; project `proj7793585f`; both subs attached to `ultimate` (`entlb89a419762`); offering `default` repointed ($rc_annual → annual sub, $rc_monthly → monthly sub, new $rc_lifetime → ultimate; dangling $rc_weekly deleted). RC metrics (`GET /v2/projects/proj7793585f/metrics/overview`) now available to revenue-ops episodes. The app's CustomerInfo fallback remains as belt-and-suspenders.
2. ~~Vendor number~~ DONE 2026-06-10: 93803823 (account-level; verified against /v1/salesReports).
3. **Experiment SKUs**: create `com.appofthedead.premium.annual.29` / `.49` ($29.99/$49.99) when starting price tests — test only structural changes at this volume (~200 subs per variant needed).
4. **Win-back offers** on the annual once churned subscribers exist (iOS 18+ surfaces them automatically).
5. **Exit offer experiment** (24h discounted annual on paywall dismissal — drove 17% of revenue in an 18-app study) — needs remote config to stay honest; owner voice forbids fake urgency, so design carefully or skip.
6. **First-lesson-free teasers** on locked paths (blurred previews) — deferred from 1.1.0 for scope.

## 4. Gates (evaluated by /revenue-ops weekly)

- **Day 30 post-1.1.0**: ≥300 downloads AND ≥5 trial starts → hold course. Else the page is the problem: re-cut screenshots 1–3, PPO-test the subtitle. <50 downloads = visibility problem: ASO iteration before any product work.
- **Day 60**: trial→paid ≥30% → press: ship experiment SKUs (follow-up 3). <20% → lengthen trial to 14 days before touching prices.
- **Day 90**: proceeds ≥ $100/mo → start the experiment ladder (localization 62.3% win rate > trial structure 59.6% > plan duration 58.7% > price 45.5% > cosmetics 34.6%). **Never ship features to fix a funnel.**
- Standing duties: reply to every review within 48h; append `docs/metrics.csv` weekly; one decision per episode.

## 5. Benchmarks to beat (Education, RevenueCat SOSA 2026)

download→trial D30 6.5% · trial→paid 5–9d 37.4% · iOS D35 download→paid 3.1% · annual share of subs 59–66% · education trial-user LTV +50.4% vs direct.

## 6. Release facts learned the hard way

- ASC API: `subscriptionAvailabilities` must be created BEFORE any `subscriptionPrices` POST — otherwise every price call 409s with `ENTITY_ERROR.RELATIONSHIP.INVALID` on the price point.
- ASC API: intro offers cannot be created territory-less; loop all 175 territories (`POST /v1/subscriptionIntroductoryOffers` each).
- ASC API: the 6.9" screenshot slot is `APP_IPHONE_67` — `APP_IPHONE_69` is not a valid enum; 1320×2868 assets upload fine under `APP_IPHONE_67`.
- ASC API: psywave's `FIRST_SUBSCRIPTION_MUST_BE_SUBMITTED_ON_VERSION` web-UI trap did NOT apply here — standalone `POST /v1/subscriptionSubmissions` worked because the app already had APPROVED products (the gate only bites apps with no approved products of any kind). Both subs rode their own review track alongside the 1.1.0 version submission (2026-06-10).

## 7. 1.1.0 submission record (2026-06-10)

- Build `202606102018` (CI run 27296776132, stable runner) attached to version 1.1.0.
- Version + Premium Annual (6778911519) + Premium Monthly (6778911344) all WAITING_FOR_REVIEW as of 18:35 UTC; review submission `33f6bb02-05b9-42f3-b611-259e2e0ae70e`.
- Annual: $39.99 × 175 territories (USA-equalized) + 7-day FREE_TRIAL intro offer × 175. Monthly: $9.99 × 175. Ultimate repriced $19.99 → $89.99; 21 paths $2.99 → $3.99 (immediate, no review needed).
- Subscription review screenshots: full paywall capture; review notes promise a dismissible paywall — keep it dismissible.

- This Mac runs beta macOS (`26A5353q`) — NEVER archive App Store builds locally (ITMS-90111 post-submission). Use `.github/workflows/testflight.yml` (stable runner, manual signing, beta guard, Metal toolchain step for mlx-swift).
- Signing lives on the app target's Release config only (manual, iphoneos-scoped) — global xcodebuild overrides break RevenueCat SPM targets.
- Xcode 26.x ships the Metal compiler as a downloadable component; fresh runners need `xcodebuild -downloadComponent MetalToolchain` before building mlx-swift.
- Intro offers on APPROVED subscriptions go live without app review; Apple applies them automatically at purchase.
- ASC: one iOS version in the pipeline at a time; Waiting for Review locks metadata; canceling a submission restarts the queue clock (~24h).
