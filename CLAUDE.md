# CLAUDE.md

Build a gamified iOS app that teaches users about afterlife beliefs across world religions using Duolingo-style mechanics.

## Project Overview
Create "App of the Dead" (aotd) - a native iOS learning app where users explore how different cultures and religions view the afterlife through bite-sized lessons, interactive quizzes, and game-like progression. Think Duolingo for comparative theology.

## Build Commands
- **Build project**: `xcodebuild -project aotd.xcodeproj -scheme aotd build`
- **Run tests**: `xcodebuild test -project aotd.xcodeproj -scheme aotd -destination 'platform=iOS Simulator,name=iPhone 17'`

## Key Technical Details
- **Database**: Uses GRDB.swift for SQLite database operations
- **UI Pattern**: Fully programmatic UIKit (no storyboards/XIBs)
- **Architecture**: MVVM pattern throughout
- **Target**: iOS 18.2+, iPhone only
- **Scene Management**: Root view controller set programmatically in `SceneDelegate.scene(_:willConnectTo:options:)`
- **Content Source**: `aotd.json` contains all learning paths, lessons, and quiz questions
- **Layout**: `App/` (entry point, services, database, MLX, shared UI), `Features/<Feature>/` (view controllers, view models and views per feature, including `Judgment` and `PathMap`), `Core/AppOfTheDeadCore` (Swift package with the content models `BeliefSystem`, `Lesson`, `Question`, `MasteryTest`, `Deity`; tests with `swift test --package-path Core/AppOfTheDeadCore`), `Resources/` (assets, catalogs, content JSON) and `Tests/aotdTests`

## Midgar platform
- **MidgarKit** from the monorepo's `packages/MidgarKit` by path (local package reference in `aotd.xcodeproj`, decision D15). The app target links the `MidgarKit` umbrella product.
- **Midgar ID**: `AotdMidgar` (App/Services) builds the identity, the gateway client and the read-only ledger store. The keychain group `cc.midgarcorp.shared` is in `App/aotd.entitlements`. No App Attest entitlement is needed: App Store and TestFlight builds attest in Apple's production environment regardless, and development builds attest in the sandbox, which the identity service accepts as the development tier.
- **Commerce**: registry engine `storekit2`: RevenueCat is not in the app (no import, no key, no linked product), and the ledger has no RevenueCat forward for it (no `RC_FORWARD_APP_OF_THE_DEAD`), so RevenueCat receives nothing about this app any more (D2). `AotdMidgar.store` is the one `MidgarStore`, in `Mode.purchases`, nil in a test host or a demo capture (`reachesMidgarServices`). `ProductIdentifier.entitlement` (`App/Models/AotdEntitlements.swift`) is the one table of product to entitlement: the store configuration (`AotdMidgar.storeConfiguration(directory:)`) and every gate read it, and `AotdEntitlementsTests` holds it equal to the registry's `[commerce.entitlements]` (keep both in step: a new product is a case of `ProductIdentifier`, a line in the registry table and a product in `Products.storekit`). The 28 products and their prices are the live App Store records (Ultimate $89.99, Oracle Wisdom $9.99, three deity packs $1.99, 21 paths $3.99, Premium monthly $2.99 and annual $19.99, with no store trial since D22). Never change product ids or prices without the founder.
- **Access**: `StoreAccess` (`App/Services/`) is the observable access model over the store: `hasAllAccess` (`ultimate`: the Ultimate unlock and both subscriptions), `hasPathAccess(_:)` (FreePaths, all access or the `path_*` entitlement), `hasUnlimitedOracle` (`oracle_unlimited` or all access) and `hasDeityPack(for:)` (`deity_*`). It is refreshed on launch, after a purchase and a restore and on every `entitlementsChanged` and `purchaseApproved` the store announces, so an Ask to Buy approval, a promoted purchase, a refund or a lapse reach the screens without a call of the app; each change posts `StoreManager.entitlementsUpdatedNotification`. `EntitlementCache` keeps the last answer so a launch with no network opens what the person owns before the store has answered; only an answer from the store replaces it, and StoreKit's current entitlements cover every owner from before the move with no network. The demo switch `AOTD_DEMO_PREMIUM=1` (DEBUG) and `FreePaths` are unchanged.
- **Purchases**: `StoreManager` buys, restores and prices through the store (`PaywallProductProviding` keeps the paywall's completion API). Prices and periods come from StoreKit through `MidgarStore.products()`; there is no store trial (D22), and the paywall still shows a trial's terms if one were ever configured (`MidgarTrialPolicy`). A purchase confirms in the foreground scene. Ask to Buy is `PurchaseOutcome.pending` (the paywall says so and closes; the unlock arrives by itself), a cancel is silent, a failure is the sentence of `StorePurchaseError`. `start()` calls `reportPurchaseHistory()` once per install so earlier buyers reach their Midgar ID in the ledger. Promoted purchases are bought by the store itself (`PurchaseIntent`).
- **StoreKit testing**: `Products.storekit` at the app root holds every product and is the Run action's StoreKit configuration. `PurchaseStoreKitTests` (`Tests/aotdTests/Integration/`) runs under `StoreKitSuites` (serial) against a `URLProtocol` stub of the gateway (`GatewayStub`). A purchase in the test host needs a window scene (`hostScene()`). Run them on the iOS 27.1 runtime with the iPhone Duo device type; the first purchase on a fresh simulator can stall, so rerun once. `SKTestSession` cannot simulate a user cancel.
- **Review prompt**: `ReviewPrompt` reports lesson completions to `MidgarReviewPolicy`; `LegacyReviewState` carries the old ask history over.
- **Privacy**: `Resources/PrivacyInfo.xcprivacy`, `store/privacy-label.md` and the policy at `web/midgarcorp/src/content/legal/app-of-the-dead/privacy.html` move together.

## 2.0: The Judgment
- **Design**: `PapyrusDesignSystem` is the night palette lit by gold (the app is dark only: the window runs `.dark`, every dynamic color resolves to the night value), New York serif for display type and SF for reading. Every `Typography` face is already scaled with Dynamic Type: never wrap one in `UIFontMetrics.scaledFont` again (it throws). Tradition and deity colors go through `PapyrusDesignSystem.Colors.tradition(_:)`, which lifts the dark inks of `aotd.json` to read on black. `UnderworldBackdropView` is the starlit background with a glow in the tradition's color. The book reader keeps its own paper themes.
- **The Judgment** (`Features/Judgment`, scoring in `Core/AppOfTheDeadCore/Judgment.swift`): nine scenes from `JudgmentScript`, each answer weighting `Virtue`s and one naming a `DeathManner`; `JudgmentEngine` rules on six traditions (`Realm`) and picks a `SoulArchetype` with its Oracle guide. It is the first run (skipping starts the free Judaism path), opens from Home and from `appofthedead://judgment`, and its Soul Card (`SoulCardRenderer`, 1080 × 1920) shares with the App Store link. `JudgmentStore` keeps the `SoulRecord` (the verdict is always recomputed from it) and mirrors it to iCloud key-value storage. Abrahamic judgment is never ruled on. Copy lives in `JudgmentCopy`; every answer id needs its copy (`SoulCardRendererTests`).
- **Premium Week** (D26, D27): `PremiumWeek` (Core) is the seven-day phase math; `PremiumWeekPass` starts it at the Judgment's verdict for anyone who owns nothing, keeps the start in the keychain (never synchronizable), and announces the end once with the plans (`PaywallReason.premiumWeekEnded`). `StoreAccess.hasEverythingOpen` is ownership or the running week; offers wait while it holds. `AOTD_DEMO_WEEK=<days>|over` fakes it in DEBUG.
- **Home**: the Soul Card or the invitation, the Premium Week chip and the Daily Omen (`DailyOmenService`: one multiple-choice or true-or-false question a day from every tradition, `DailyOmenSchedule` in Core; a right answer earns 10 XP, any answer keeps the streak).
- **Paths**: a tradition opens on `PathMapViewController` (lessons done, next, ahead, then the mastery crown); lessons start from the map and return to it. A locked path's preview still plays lesson 1 straight away. Lessons are story cards (`LessonViewModel.cards`, about 280 characters of whole sentences each) then key terms, then the quiz.
- **Oracle**: `OracleVoice` answers with Apple's on-device model (`MidgarOnDeviceModel`) wherever Apple Intelligence runs and falls back to the Gemma download elsewhere; the book explanations use it too. `OraclePrompt` grounds each answer in sentences from the deity's own paths (`pathsByDeity`), keeps the last two turns, and forbids quoted scripture. `CompassionGuard` answers first-person self-harm messages in the app's own voice with findahelpline.com, never a persona's. A refusal reads "<deity> is silent on this". Replies share as cards (`OracleQuoteRenderer`). `AOTD_ORACLE_ASK=<question>` with `AOTD_DEMO_DEITY` asks the real model on launch (DEBUG).
- **Settings** (`Features/Settings`) is MidgarUI's `MidgarSettingsViewController` in the `.aotd` theme, embedded as a child: `SettingsMembershipCard` (free, Premium Week or member) and the Midgar card on top, then Purchases (Manage Subscription only for a current StoreKit subscription, Restore), Your Journey (Soul Card or the Judgment, Daily Reminder, Game Center), The Oracle (voice, Remove Downloaded Model with its size, streaming haptics for the downloaded model), Share & Support (rate, share, support mail), About (usage counts, `Licenses`, privacy, terms, version) and Delete Midgar ID. `SettingsLayout` decides the rows from a `SettingsState`, so every combination is a unit test (`SettingsViewModelTests`); `SettingsViewModel` reads the live state and runs restore, model removal and the ID deletion.
- **Screenshot rig** routes added: `judgment`, `judgment-scene` (`AOTD_DEMO_SCENE`), `judgment-weighing`, `judgment-verdict`, `path-map` (`AOTD_DEMO_PATH`).

## Core Features to Implement
1. **Learning Paths**: Multiple belief system tracks (Judaism, Christianity, Islam, Buddhism, etc.)
2. **Lesson Flow**: Content screen → Quiz questions → Progress update
3. **Question Types**: Multiple choice, matching, true/false with immediate feedback
4. **Gamification**: XP system, achievements, streaks, level progression
5. **Progress Tracking**: Unlock new paths, visual progress indicators.

## Development Patterns
- Follow the existing programmatic UI approach - no Interface Builder
- Use the PapyrusDesignSystem for all user interfaces
- Use UIStackView's heavily to simplify the layout code. UIStackView's are very configurable and performant.
- Always use the latest UIKit APIs like diffable datasource
- Use MVVM architecture for all screens
- Always unit test new view models.
- GRDB for all data persistence (models: User, Progress, Achievement, CompletedLesson)
- UIKit only - No SwiftUI
- Analyze `aotd.json` structure before implementing content loading
- Write and run unit tests for logic when adding new features.
- Keep view controllers focused - delegate business logic to view models. Use latest UIKit API like diffable datasource etc.
- Use coordinators for navigation flow between lessons and quizzes
- Prefer Protocol-Oriented-Programming over Object-Oriented-Programming
- **Logging**: Use `MidgarLog` (MidgarCore) for all logging, with the categories in `App/Utilities/LogCategories.swift` (`.database`, `.content`, `.learning`, `.gamification`, `.gameCenter`, `.purchases`, `.ui`, `.viewModel`, `.mlx`, `.performance`, `.general`); `Diagnostics` adds `logError`, `logUserAction` and timed activities on top. Never use `print()` statements. The file log is `Library/Logs/aotd.log`.
- **Code Style**: Never use comments or MARK statements - code should be self-documenting through clear naming and structure

## Test Organization
- **Tests are organized by feature area in the test target** for better discoverability while remaining in the test bundle
  - Example: `App/Models/User.swift` → `Tests/aotdTests/Models/UserTests.swift`
  - Example: `Features/Home/HomeViewModel.swift` → `Tests/aotdTests/ViewModels/HomeViewModelTests.swift`
- **Test directory structure mirrors source directory structure**:
  - `Tests/aotdTests/Models/` - Model tests
  - `Tests/aotdTests/Database/` - Database and JSON validation tests
  - `Tests/aotdTests/ViewModels/` - ViewModel tests
  - `Tests/aotdTests/Services/` - Service tests (Auth, Gamification, etc.)
  - `Tests/aotdTests/Integration/` - Integration tests that test flows across multiple components
- **Only write tests that provide real value**:
  - Test actual implementations, not stubs
  - Test business logic, data persistence, and complex operations
  - Skip trivial tests that don't add value
- **When adding tests**:
  - Place tests in the corresponding directory within Tests/aotdTests
  - Name tests as `<SourceFileName>Tests.swift`
  - For multiple test files testing the same class, use descriptive suffixes (e.g., `HomeViewModelSortingTests.swift`)

## Claude Working Principles
- **Before implementing**: Search for 2-3 similar patterns in the codebase to follow
- **For complex tasks**: Internally decompose into sub-problems before starting
- **After implementing**: Self-check the solution for edge cases and potential issues
- **Consider alternatives**: Think of 2-3 approaches and pick the best one
- **Gather context first**: Read relevant files and understand constraints before coding

## UI/UX Guidelines
- Beautiful, modern design. You are a master iOS designer. Design of the year award winner app.
- Distinct color themes per belief system. Color codes are in aotd.json
- Haptic feedback for all interactions, but according to Apple's Human Interface Guidelines
- Smooth animations for correct/incorrect answers
- Accessibility: VoiceOver labels, Dynamic Type support
- Offline-first: all content available without internet

When implementing new features, always check `aotd.json` for the expected data structure and maintain consistency with existing MVVM patterns.
