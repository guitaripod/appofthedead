# CLAUDE.md

Build a gamified iOS app that teaches users about afterlife beliefs across world religions using Duolingo-style mechanics.

## Project Overview
Create "App of the Dead" (aotd) - a native iOS learning app where users explore how different cultures and religions view the afterlife through bite-sized lessons, interactive quizzes, and game-like progression. Think Duolingo for comparative theology.

## Build Commands
- **Build project**: `xcodebuild -project aotd.xcodeproj -scheme aotd build`
- **Run tests**: `xcodebuild test -project aotd.xcodeproj -scheme aotd -destination 'platform=iOS Simulator,name=iPhone 16'`

## Key Technical Details
- **Database**: Uses GRDB.swift for SQLite database operations
- **UI Pattern**: Fully programmatic UIKit (no storyboards/XIBs)
- **Architecture**: MVVM pattern throughout
- **Target**: iOS 18.2+, iPhone only
- **Scene Management**: Root view controller set programmatically in `SceneDelegate.scene(_:willConnectTo:options:)`
- **Content Source**: `aotd.json` contains all learning paths, lessons, and quiz questions

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
- **Logging**: Use `AppLogger` for all logging - never use `print()` statements. AppLogger provides structured logging with categories (auth, database, content, sync, learning, gamification, purchases, ui, viewModel, mlx, performance, general)

## UI/UX Guidelines
- Beautiful, modern design. You are a master iOS designer. Design of the year award winner app.
- Distinct color themes per belief system. Color codes are in aotd.json
- Haptic feedback for all interactions, but according to Apple's Human Interface Guidelines
- Smooth animations for correct/incorrect answers
- Accessibility: VoiceOver labels, Dynamic Type support
- Offline-first: all content available without internet

When implementing new features, always check `aotd.json` for the expected data structure and maintain consistency with existing MVVM patterns.

## Recent Updates
- **Deity Selection UI**: Reverted to simple modal presentation without navigation bar or search functionality
- Using diffable data source for deity collection view
- Added grabber handle for dismissal with pan gesture support
- Fixed dark mode colors to match app's design system
- Expanded deity list from 9 to 21 deities in `deity_prompts.json`

