# Book Reading Features

## Overview
Comprehensive book reading experience with extensive customization options and oracle integration for text explanations.

## Implemented Features

### 1. Reading Preferences (BookReadingPreferences model)
- **Font Settings**:
  - Font size (12-32pt)
  - Font family (Georgia, Palatino, Baskerville, Times New Roman, Helvetica Neue, San Francisco, Avenir, Charter)
  - Font weight (Light, Regular, Medium, Semibold, Bold)
  
- **Text Layout**:
  - Text alignment (Left, Center, Right, Justified)
  - Line spacing (1.0-2.5)
  - Paragraph spacing (1.0-2.0)
  - First line indent (0-50pt)
  - Margins (10-50pt)
  - Hyphenation toggle

- **Visual Themes**:
  - Papyrus (default)
  - Night mode
  - Sepia
  - High contrast
  - Ocean theme
  - Each theme includes custom background, text, and highlight colors

- **Reading Features**:
  - Page transition style (Scroll/Page Turn)
  - Show page progress indicator
  - Keep screen on while reading
  - Enable swipe gestures
  - Brightness control
  - Auto-scroll speed
  - Text-to-speech speed and voice selection

### 2. Book Reader Settings (BookReaderSettingsViewController)
- Comprehensive settings modal with 4 sections:
  - Appearance (theme, font, brightness)
  - Text Layout (alignment, spacing, indentation)
  - Reading Features (transitions, progress, gestures)
  - Automation (auto-scroll, TTS settings)
- Real-time preview of settings changes
- Custom cells for different setting types
- Visual theme previews with color swatches

### 3. Text Selection & Oracle Integration
- **Custom Text Selection Handler**:
  - Long press to select words
  - Custom menu with oracle-specific actions
  - Multiple highlight colors (yellow, blue, green)
  - Add notes to highlights
  - Share selected text
  - System dictionary lookup

- **Oracle Text Explanation**:
  - "Ask Oracle 🔮" menu option
  - Beautiful modal overlay with deity avatar
  - Context-aware explanations using selected text and surrounding content
  - Save oracle explanations linked to highlights
  - Deity-specific responses based on selected deity

### 4. Highlight System
- **Persistent Highlights**:
  - Database storage with BookHighlight model
  - Links to oracle consultations
  - Multiple color options
  - Optional notes
  - Chapter-specific tracking

- **Visual Rendering**:
  - Applied to text view with background colors
  - Preserved across reading sessions
  - Synced with reading position

### 5. Enhanced Reading Experience
- **Navigation**:
  - Chapter-based navigation with smooth transitions
  - Previous/Next chapter buttons
  - Reading position restoration
  - Progress tracking per chapter and overall book

- **Visual Features**:
  - Papyrus texture background
  - Theme-aware UI elements
  - Smooth animations for controls
  - Haptic feedback for interactions

- **Reading Tools**:
  - Auto-scroll with adjustable speed
  - Text-to-speech with voice selection
  - Bookmark support
  - Reading time tracking
  - Progress percentage display

## Technical Implementation

### Database Schema
```sql
-- BookHighlight table
CREATE TABLE book_highlights (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    bookId TEXT NOT NULL,
    chapterId TEXT NOT NULL,
    startPosition INTEGER NOT NULL,
    endPosition INTEGER NOT NULL,
    highlightedText TEXT NOT NULL,
    color TEXT NOT NULL,
    note TEXT,
    oracleConsultationId TEXT,
    createdAt DATETIME NOT NULL,
    updatedAt DATETIME NOT NULL,
    FOREIGN KEY (userId) REFERENCES users(id),
    FOREIGN KEY (bookId) REFERENCES books(id),
    FOREIGN KEY (oracleConsultationId) REFERENCES oracle_consultations(id)
);
```

### Key Components
1. **BookReaderTextView**: Custom UITextView subclass for selection handling
2. **BookReaderTextSelectionHandler**: Manages text selection and custom menu
3. **OracleTextExplanationView**: Modal view for oracle responses
4. **BookReaderSettingsViewController**: Comprehensive settings interface
5. **Reading Theme System**: Predefined color schemes with dark mode support

### Integration Points
- Uses MLXService for oracle AI responses
- Integrates with existing OracleConsultation model
- Saves reading preferences to database
- Syncs highlights across sessions
- Tracks reading progress and time

## Usage

Users can:
1. Long press text to select and get oracle explanations
2. Customize every aspect of the reading experience
3. Save highlights with notes and oracle insights
4. Navigate chapters with preserved reading positions
5. Use auto-scroll or TTS for hands-free reading
6. Switch between multiple visual themes
7. Adjust text layout for optimal readability

## Future Enhancements (Not Yet Implemented)
- Table of contents view
- Text search within books
- Reading statistics and analytics
- Gesture controls for page turning and brightness
- Export highlights and notes
- Social sharing of quotes with attribution