# App of the Dead

[Download on the App Store](https://apps.apple.com/app/id6746733380)

Where will your soul go? App of the Dead opens with the Judgment: nine questions from guardians of the dead weigh your soul by the rules of six traditions (Egyptian, Greek, Norse, Aztec, Zoroastrian and Buddhist) and hand back a shareable Soul Card. Then learn what the world's religions believe about the afterlife, a few minutes at a time: each of 22 traditions is a path of story-card lessons and quizzes (multiple choice, matching, true or false) on a map of its own, with XP, streaks, a Daily Omen and Game Center achievements. The Oracle lets you ask deities questions through a language model that runs on the iPhone: Apple's on-device model where Apple Intelligence is available, otherwise Gemma 4 after a one-time download. The Judgment opens every path for a week; the Judaism path is free; other paths, deity packs, unlimited Oracle and an all-access Ultimate unlock or Premium subscription are in-app purchases.

## Layout

```
App/                     entry point, services, GRDB database, on-device model (MLX), shared UI
Features/<Feature>/      view controllers, view models and views per feature (programmatic UIKit, MVVM)
Core/AppOfTheDeadCore/   Swift package with the content models: BeliefSystem, Lesson, Question, MasteryTest, Deity
Resources/               assets, string catalog, belief_systems/ (one JSON file per path: lessons and questions), achievements
Tests/aotdTests/         unit and StoreKit tests
```

## Build

iOS 18.2 or later, iPhone. MidgarKit is a local package in the Midgar monorepo (`packages/MidgarKit`).

```
open aotd.xcodeproj
xcodebuild test -project aotd.xcodeproj -scheme aotd -destination 'platform=iOS Simulator,name=iPhone 17'
swift test --package-path Core/AppOfTheDeadCore
```

`Products.storekit` holds every product for local purchase testing.
