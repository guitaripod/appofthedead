# CLAUDE.md

## Build Commands

- **Build project**: Open `appofthedead.xcodeproj` in Xcode and use Cmd+B, or use `xcodebuild -project appofthedead.xcodeproj -scheme appofthedead build`
- **Run app**: Use Xcode's Run button (Cmd+R) or iOS Simulator

## Key Technical Details

- **Database**: Uses GRDB.swift for SQLite database operations
- **UI Pattern**: Fully programmatic UI
- **Target**: iOS 18.2+, supports iPhone
- **Scene Management**: Root view controller set programmatically in `SceneDelegate.scene(_:willConnectTo:options:)`

## Development Patterns

- Follow the existing programmatic UI approach rather than using storyboards
- Use MVVM
- Use GRDB
- Use UIKit
- Use the appofthedead.json file to analyze the data used for the learning paths
