import UIKit
import MidgarCore

extension BookReaderViewController {
    
    func setupTextSelection() {
        textSelectionHandler = BookReaderTextSelectionHandler(textView: textView)
        textSelectionHandler?.delegate = self
        textSelectionHandler?.configureTextView()
        
        
        textView.selectionHandler = textSelectionHandler
    }
    
    func loadHighlights() {
        Task {
            do {
                guard let user = DatabaseManager.shared.fetchUser() else { return }
                currentHighlights = try DatabaseManager.shared.getBookHighlights(
                    userId: user.id,
                    bookId: viewModel.book.id
                )
                applyHighlights()
            } catch {
                MidgarLog.error("Failed to load highlights: \(error)", category: .database)
            }
        }
    }
    
    private func applyHighlights() {
        
        highlightViews.forEach { $0.removeFromSuperview() }
        highlightViews.removeAll()
        
        
        guard let attributedText = textView.attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        for highlight in currentHighlights {
            let range = NSRange(location: highlight.startPosition, length: highlight.endPosition - highlight.startPosition)
            
            
            guard range.location + range.length <= mutableText.length else { continue }
            
            
            let color = UIColor(hex: highlight.color) ?? UIColor(hex: viewModel.preferences.highlightColor) ?? UIColor.yellow.withAlphaComponent(0.3)
            mutableText.addAttribute(.backgroundColor, value: color, range: range)
        }
        
        textView.attributedText = mutableText
    }
    
    func saveHighlight(text: String, range: NSRange, color: UIColor, note: String? = nil, oracleConsultationId: String? = nil) {
        Task {
            do {
                guard let user = DatabaseManager.shared.fetchUser() else { return }
                
                
                var chapterId = viewModel.book.chapters[0].id
                for (index, startPos) in chapterStartPositions.enumerated() {
                    if range.location >= startPos {
                        chapterId = viewModel.book.chapters[index].id
                    }
                }
                
                let highlight = BookHighlight(
                    id: UUID().uuidString,
                    userId: user.id,
                    bookId: viewModel.book.id,
                    chapterId: chapterId,
                    startPosition: range.location,
                    endPosition: range.location + range.length,
                    highlightedText: text,
                    color: color.toHexString(),
                    note: note,
                    oracleConsultationId: oracleConsultationId,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try DatabaseManager.shared.saveBookHighlight(highlight)
                currentHighlights.append(highlight)
                applyHighlights()
                
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
            } catch {
                MidgarLog.error("Failed to save highlight: \(error)", category: .database)
            }
        }
    }
    
    func showOracleExplanation(for text: String, range: NSRange) {

        let contextRange = NSRange(
            location: max(0, range.location - 100),
            length: min(textView.text.count - range.location, range.length + 200)
        )
        let context = (textView.text as NSString).substring(with: contextRange)


        let oracleView = OracleTextExplanationView(
            selectedText: text,
            bookContext: context,
            deityId: oracleDeityId()
        )
        oracleView.delegate = self
        activeOracleExplanation = oracleView
        oracleView.show(in: view)
    }

    func oracleDeityId() -> String {
        ContentLoader().getDeityForBeliefSystem(viewModel.book.beliefSystemId)?.id ?? "the_eternal"
    }
    
    func shareText(_ text: String) {
        let activityVC = UIActivityViewController(
            activityItems: [text, String(localized: "From \"\(viewModel.book.title)\" in App of the Dead"), AppStoreListing.url],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = textView
            popover.sourceRect = textView.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    func showNoteEditor(for text: String, range: NSRange) {
        let alert = UIAlertController(title: String(localized: "Add Note"), message: String(localized: "Add a note for this highlighted text"), preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = String(localized: "Enter your note...")
            textField.autocapitalizationType = .sentences
        }
        
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Save"), style: .default) { [weak self] _ in
            if let note = alert.textFields?.first?.text, !note.isEmpty {
                self?.saveHighlight(text: text, range: range, color: PapyrusDesignSystem.Colors.goldLeaf, note: note)
            }
        })
        
        present(alert, animated: true)
    }
    
    func applyReadingPreferences() {
        
        applyTheme(viewModel.preferences.theme)
        
        
        view.alpha = CGFloat(viewModel.preferences.brightness)
        
        
        applyTextAlignment()
        
        
        UIApplication.shared.isIdleTimerDisabled = viewModel.preferences.keepScreenOn
        
        updateContent()
    }
    
    private func applyTheme(_ themeName: String) {
        guard let theme = ReadingTheme.themes[themeName] else { return }
        
        
        view.backgroundColor = theme.backgroundColor
        textView.backgroundColor = .clear
        textView.textColor = theme.textColor
        
        
        headerView.backgroundColor = theme.isDark ? theme.backgroundColor : PapyrusDesignSystem.Colors.beige
        bottomToolbar.backgroundColor = theme.isDark ? theme.backgroundColor : PapyrusDesignSystem.Colors.beige
        
        
        let controlTint = theme.isDark ? theme.textColor : PapyrusDesignSystem.Colors.ancientInk
        backButton.tintColor = controlTint
        settingsButton.tintColor = controlTint
        previousChapterButton.tintColor = controlTint
        nextChapterButton.tintColor = controlTint
        bookmarkButton.tintColor = controlTint
        speechButton.tintColor = controlTint
        playPauseButton.tintColor = theme.isDark ? theme.highlightColor : PapyrusDesignSystem.Colors.goldLeaf
        
        
        titleLabel.textColor = controlTint
        chapterLabel.textColor = theme.secondaryTextColor
        readingTimeLabel.textColor = theme.secondaryTextColor
        percentageLabel.textColor = theme.secondaryTextColor
        
        
        papyrusBackgroundView.alpha = theme.isDark ? 0.05 : 0.3
    }
    
    private static let readableTextWidth: CGFloat = 640

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        foldAvoiding.update(in: view)
        keepTextColumnReadable()
    }

    /// A wide window keeps the text to a comfortable measure and centres the column, instead of
    /// running lines across the whole display.
    private func keepTextColumnReadable() {
        guard !AdaptiveLayoutManager.shared.isIPad else { return }
        let current = textView.textContainerInset
        let margin = max(CGFloat(viewModel.preferences.marginSize), (textView.bounds.width - Self.readableTextWidth) / 2)
        guard abs(current.left - margin) > 0.5 else { return }
        textView.textContainerInset = UIEdgeInsets(top: current.top, left: margin, bottom: current.bottom, right: margin)
    }

    func applyTextAlignment() {
        let margin = CGFloat(viewModel.preferences.marginSize)
        textView.textContainerInset = UIEdgeInsets(top: 120, left: margin, bottom: 100, right: margin)
        updateContent()
    }
    
    func updateContent() {
        chapterStartPositions.removeAll()
        
        let attributedString = NSMutableAttributedString()
        
        
        let font = getFont()
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(viewModel.preferences.lineSpacing * 8)
        paragraphStyle.paragraphSpacing = CGFloat(viewModel.preferences.paragraphSpacing * 12)
        paragraphStyle.firstLineHeadIndent = CGFloat(viewModel.preferences.firstLineIndent)
        paragraphStyle.hyphenationFactor = viewModel.preferences.enableHyphenation ? 1.0 : 0.0
        
        switch viewModel.preferences.textAlignment {
        case "left":
            paragraphStyle.alignment = .left
        case "center":
            paragraphStyle.alignment = .center
        case "right":
            paragraphStyle.alignment = .right
        case "justified":
            paragraphStyle.alignment = .justified
        default:
            paragraphStyle.alignment = .justified
        }
        
        let theme = ReadingTheme.themes[viewModel.preferences.theme] ?? ReadingTheme.themes["papyrus"]!
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        
        for chapter in viewModel.book.chapters {
            
            chapterStartPositions.append(attributedString.length)
            
            
            let titleFont = getFont(size: viewModel.preferences.fontSize + 6, weight: .bold)
            let chapterTitle = NSMutableAttributedString(string: "\(chapter.title)\n\n", attributes: [
                .font: titleFont,
                .foregroundColor: theme.textColor,
                .paragraphStyle: paragraphStyle
            ])
            attributedString.append(chapterTitle)
            
            
            let chapterContent = NSAttributedString(string: chapter.content + "\n\n\n", attributes: baseAttributes)
            attributedString.append(chapterContent)
        }
        
        textView.attributedText = attributedString
        
        
        applyHighlights()
    }
    
    private func getFont(size: CGFloat? = nil, weight: UIFont.Weight? = nil) -> UIFont {
        let fontSize = CGFloat(size ?? viewModel.preferences.fontSize)
        let fontWeight = weight ?? getFontWeight()
        
        if let customFont = UIFont(name: viewModel.preferences.fontFamily, size: fontSize) {
            
            let weightTrait = UIFontDescriptor.SymbolicTraits()
            let weightValue: CGFloat
            
            switch fontWeight {
            case .ultraLight:
                weightValue = -0.8
            case .thin:
                weightValue = -0.6
            case .light:
                weightValue = -0.4
            case .regular:
                weightValue = 0.0
            case .medium:
                weightValue = 0.23
            case .semibold:
                weightValue = 0.3
            case .bold:
                weightValue = 0.4
            case .heavy:
                weightValue = 0.56
            case .black:
                weightValue = 0.62
            default:
                weightValue = 0.0
            }
            
            let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weightValue]
            let descriptor = customFont.fontDescriptor.addingAttributes([.traits: traits])
            return UIFont(descriptor: descriptor, size: fontSize)
        }
        
        return UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
    }
    
    private func getFontWeight() -> UIFont.Weight {
        switch viewModel.preferences.fontWeight {
        case "light":
            return .light
        case "regular":
            return .regular
        case "medium":
            return .medium
        case "semibold":
            return .semibold
        case "bold":
            return .bold
        default:
            return .regular
        }
    }
}
