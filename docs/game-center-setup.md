# Game Center Setup (App Store Connect)

The app-side Game Center integration is complete and shipping (entitlement, authentication,
leaderboard/achievement submission, dashboard, access point). The **only** remaining steps are
account-side records in App Store Connect + the App ID capability. These require the Apple
Developer account and must match the IDs below **exactly** — the app submits to these literal IDs.

## 1. App ID capability

Developer portal → Identifiers → `com.marcusziade.aotd` → enable **Game Center**.
Re-generate / re-download the distribution provisioning profile afterward (manual signing flow
in `~/.config/midgar/OPERATIONS.md`). The `com.apple.developer.game-center` entitlement is already
in `aotd/aotd.entitlements`.

## 2. Leaderboards (classic, all-time)

App Store Connect → the app → **Features → Game Center → Leaderboards**. Create five **Classic**
leaderboards. Score format **Integer**, sort order **High to Low**. IDs are defined in
`GameCenterLeaderboard.swift`.

| Leaderboard Reference Name | Leaderboard ID                                   | Submitted value          |
|----------------------------|--------------------------------------------------|--------------------------|
| Total Enlightenment        | `com.marcusziade.aotd.leaderboard.total_xp`      | `User.totalXP`           |
| Days of Devotion           | `com.marcusziade.aotd.leaderboard.current_streak`| `User.streakDays` (best) |
| Realms Mastered            | `com.marcusziade.aotd.leaderboard.paths_mastered`| mastered path count      |
| Gates Walked               | `com.marcusziade.aotd.leaderboard.paths_completed`| completed+mastered paths |
| Sacred Knowledge           | `com.marcusziade.aotd.leaderboard.correct_answers`| correct answers count    |

Each leaderboard needs at least one localization (English) with a display name and a score-format
suffix (e.g. "XP", "days", "realms", "gates", "answers"). Optionally add a leaderboard description
and a 512×512 image — these only affect visibility in the iOS 18+ **Games** app, which surfaces
apps whose primary category is *Games*. AOTD's category is *Education*, so it won't appear there;
the leaderboards/achievements still work fully in-app via the trophy button → `GKGameCenterViewController`
dashboard. Score format **Best (keep highest)** is what makes the `current_streak` board behave as
"longest streak ever".

## 3. Achievements

App Store Connect → **Features → Game Center → Achievements**. Create one achievement per row.
Each record has a **Reference Name** (private) and an **Achievement ID** (the string the app
reports against). The **Achievement ID must equal the in-app achievement id** (from
`aotd/Resources/achievements.json`) so `GameCenterManager.synchronize()` can report progress 1:1
with zero mapping. The app reports `percentComplete` continuously (not just on unlock); Game Center
stores it as an integer 0–100 (matching the snapshot's rounding). GC's own completion banner is
suppressed in code (`showsCompletionBanner = false`) because the app shows its own
`AchievementNotificationView`; Apple still records the unlock.

Apple's hard limits: **max 100 points per achievement**, max 100 achievements, **≤ 1000 points
total** per app. The split below respects all three (totals 700, leaving 300 budget for future
achievements — Apple recommends not spending the whole budget on v1).

| Achievement ID          | Reference Name / Title | Points | Hidden |
|-------------------------|------------------------|--------|--------|
| `first_step`            | First Step             | 20     | No     |
| `quiz_whiz`             | Quiz Whiz              | 40     | No     |
| `enlightened_one`       | Enlightened One        | 60     | No     |
| `perfect_understanding` | Perfect Understanding  | 60     | No     |
| `scholar_of_sheol`      | Scholar of Sheol       | 70     | No     |
| `journey_through_duat`  | Journey Through Duat   | 70     | No     |
| `wisdom_seeker`         | Wisdom Seeker          | 80     | No     |
| `eternal_student`       | Eternal Student        | 100    | No     |
| `cosmic_explorer`       | Cosmic Explorer        | 100    | No     |
| `afterlife_master`      | Afterlife Master       | 100    | No     |

Total: 700 (≤ 1000, every value ≤ 100). Each achievement needs an English localization (title +
pre/post-earned description — reuse the `description` from `achievements.json`) and a 512×512 PNG
artwork.

> **Get points right the first time:** once an achievement is live for any app version, its point
> value can't be changed and the achievement can't be deleted.

## 4. Verification

- Sandbox: sign into a Sandbox Apple ID (Settings → Game Center) on the device/simulator, launch
  the app, earn XP, and confirm scores/achievements appear via the in-app trophy button (Profile).
- The app authenticates on launch (`SceneDelegate`), re-syncs on foreground, and coalesces a sync
  ~1s after every `UserDataDidUpdate`, so values are eventually-consistent and self-healing.
