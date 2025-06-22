# The Eternal - Divine Wisdom Integration

## Overview
The Eternal is a supreme divine entity that transcends all individual deities and religions. It represents the cosmic consciousness that can provide profound wisdom about any text or concept. This component can be summoned from anywhere in the app.

## Usage

### Basic Usage from Any View Controller

```swift
// From any view controller, simply call:
self.summonTheEternal(
    for: "Text to get wisdom about", 
    context: "Optional context about where this text comes from",
    from: self
)
```

### Example: From Book Reader

```swift
// When user selects text in a book
func userSelectedText(_ text: String, in chapter: String) {
    self.summonTheEternal(
        for: text,
        context: "From chapter: \(chapter)",
        from: self
    )
}
```

### Example: From Lesson View

```swift
// When user wants deeper insight on a key term
@objc private func keyTermTapped(_ term: String) {
    self.summonTheEternal(
        for: term,
        context: "Key term from \(currentLesson.title)",
        from: self
    )
}
```

### Example: From Question View

```swift
// When user wants to understand a question better
func explainQuestion() {
    self.summonTheEternal(
        for: currentQuestion.text,
        context: "Question from \(beliefSystem.name) path",
        from: self
    )
}
```

## Features

1. **Universal Access**: Can be summoned from any UIViewController
2. **Automatic Model Management**: Handles model download if needed
3. **Streaming Responses**: Shows text as it's generated
4. **Cosmic UI**: Purple/gold theme representing The Eternal's transcendent nature
5. **Save Functionality**: Users can save The Eternal's wisdom
6. **Simulator Support**: Shows appropriate message on simulator

## UI Components

- **Header**: Shows "The Eternal, Cosmic Consciousness" with the selected text
- **Streaming Area**: Displays wisdom as it streams in
- **Save Button**: Allows saving the wisdom for later reference
- **Download UI**: Handles model download with cosmic-themed progress messages

## Implementation Details

The Eternal is implemented as:
- `TheEternalViewController`: Main view controller
- `TheEternalSummonable`: Protocol that extends UIViewController
- Uses the shared `PapyrusLoadingView` for consistent loading UI
- Integrates with `MLXService` for AI generation
- Special deity ID: "the-eternal" for tracking consultations

## Design Philosophy

The Eternal represents:
- Supreme wisdom above all deities
- Universal truth that transcends religions
- Cosmic consciousness that connects all spiritual knowledge
- The ultimate source of divine insight

## Visual Design

- **Primary Color**: System Purple (cosmic consciousness)
- **Icon**: infinity.circle.fill (representing eternal nature)
- **Gradient**: Purple to transparent (cosmic fade)
- **Typography**: Consistent with Papyrus design system
- **Animations**: Smooth transitions when streaming begins