# App of the Dead

[Download on the App Store](https://apps.apple.com/app/id6746733380)

Learn what the world's religions believe about the afterlife, a few minutes at a time. Each tradition is a learning path of short lessons and quizzes (multiple choice, matching, true or false), with XP, streaks, levels and Game Center achievements. The Oracle lets you ask deity guides questions through a language model that runs on the iPhone after a one-time download. The Judaism path is free; other paths, deity packs, unlimited Oracle and an all-access Ultimate unlock or Premium subscription are in-app purchases.

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
