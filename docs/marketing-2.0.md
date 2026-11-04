# App of the Dead 2.0: store set and baseline (2026-11-04)

## Baseline

- First-time downloads: 30 in the 30 days to 2026-11-02 (`myyty app "app of the dead" --last 30d`), 43 in 45 days; 0 in-app purchases ever.
- Funnel (App Store Discovery & Engagement, August 2026, `docs/growth-plan.md`): 2,494 impressions (95% search), 8.5% to product page, 19% of page views tap Get. Conversion is normal; impressions are the constraint.
- Search position (iTunes Search API, US, 2026-11-04): #17 for "afterlife", #7 for "religions quiz", absent from the top 20 for "mythology", "mythology quiz", "world religions", "greek gods", "egyptian gods".

## What 2.0 changes on the page

- Subtitle "Afterlife & Mythology Quiz" (was "Mythology Quiz & Talk to Gods"); keywords from live App Store search hints: heaven, hell, judgment, gods, greek, norse, egyptian, soul, death, underworld, oracle, world, trivia, chat, ai. Every locale's subtitle and keywords were rewritten the same way.
- iPhone 6.9" set of eight in en-US (the Judgment's verdict first) and five localized shots in the ten UI languages; iPad 13" set of five in en-US. Composed by `marketing/compose_store_shots.py` from simulator captures; framed with `frames`.
- iOS 27 Product Page Header (text-free, three iPhones) and Search Results asset (the verdict beside "Where will your soul go?") per locale, by `marketing/compose_creative.py`, placed by `scripts/asc-creative.py`.
- In-app event "Face the Judgment" (`store/events/judgment-2026`), MAJOR_UPDATE, deep link `appofthedead://judgment`, riding the 2.0 submission.

## Targets (read with `myyty` and the Discovery & Engagement report)

| Window after release | Target |
|---|---|
| 30 days | 60 first-time downloads (2 a day), impressions up 50% on August, 5 ratings |
| 60 days | the first paid unlock or subscription after a Premium Week |
| 90 days | $100 a month in proceeds, else maintenance (`docs/2.0-design.md`, Gates) |
