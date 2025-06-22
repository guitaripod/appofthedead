import UIKit
import AVFoundation

final class BookReaderViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: BookReaderViewModel
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var readingTimer: Timer?
    private var panGestureStartPosition: CGFloat = 0
    private var autoScrollTimer: Timer?
    private var controlsHidden = false
    private var isNavigatingChapter = false
    private var hasRestoredPosition = false
    private var textSelectionHandler: BookReaderTextSelectionHandler?
    private var currentHighlights: [BookHighlight] = []
    private var highlightViews: [UIView] = []
    private var chapterStartPositions: [Int] = []
    
    // MARK: - UI Components
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = PapyrusDesignSystem.Colors.ancientInk
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.title3()
        label.textColor = PapyrusDesignSystem.Colors.ancientInk
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "textformat.size"), for: .normal)
        button.tintColor = PapyrusDesignSystem.Colors.ancientInk
        button.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var chapterLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var textView: BookReaderTextView = {
        let textView = BookReaderTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 120, left: 20, bottom: 100, right: 20)
        textView.showsVerticalScrollIndicator = false
        textView.delegate = self
        return textView
    }()
    
    private lazy var papyrusBackgroundView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.3
        return imageView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = PapyrusDesignSystem.Colors.goldLeaf
        progress.trackTintColor = PapyrusDesignSystem.Colors.secondaryText.withAlphaComponent(0.2)
        return progress
    }()
    
    private lazy var bottomToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        return view
    }()
    
    private lazy var previousChapterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = PapyrusDesignSystem.Colors.ancientInk
        button.addTarget(self, action: #selector(previousChapterTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        button.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        return button
    }()
    
    private lazy var nextChapterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = PapyrusDesignSystem.Colors.ancientInk
        button.addTarget(self, action: #selector(nextChapterTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.tintColor = PapyrusDesignSystem.Colors.ancientInk
        button.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var percentageLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        label.textAlignment = .right
        return label
    }()
    
    private lazy var readingTimeLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        label.textAlignment = .left
        return label
    }()
    
    
    // MARK: - Lifecycle
    
    init(viewModel: BookReaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextSelection()
        bindViewModel()
        startReadingTimer()
        
        // Load initial content
        viewModel.loadCurrentChapter()
        
        // Load highlights
        loadHighlights()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSpeech()
        stopReadingTimer()
        viewModel.saveProgress()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: viewModel.preferences.backgroundColor) ?? PapyrusDesignSystem.Colors.background
        
        // Add subviews
        view.addSubview(papyrusBackgroundView)
        view.addSubview(textView)
        view.addSubview(headerView)
        view.addSubview(bottomToolbar)
        
        // Add papyrus texture
        createPapyrusTexture()
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(settingsButton)
        headerView.addSubview(chapterLabel)
        headerView.addSubview(progressView)
        
        bottomToolbar.addSubview(previousChapterButton)
        bottomToolbar.addSubview(playPauseButton)
        bottomToolbar.addSubview(nextChapterButton)
        bottomToolbar.addSubview(bookmarkButton)
        bottomToolbar.addSubview(readingTimeLabel)
        bottomToolbar.addSubview(percentageLabel)
        
        // Setup constraints
        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        previousChapterButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        nextChapterButton.translatesAutoresizingMaskIntoConstraints = false
        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        readingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        papyrusBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Papyrus background
            papyrusBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            papyrusBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            papyrusBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            papyrusBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8),
            
            settingsButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            settingsButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            chapterLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            chapterLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            chapterLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            progressView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            // Text View
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Bottom Toolbar
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Toolbar buttons
            playPauseButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            
            previousChapterButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            previousChapterButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            
            nextChapterButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            nextChapterButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            
            bookmarkButton.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -20),
            bookmarkButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            
            readingTimeLabel.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 20),
            readingTimeLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            percentageLabel.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -20),
            percentageLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        
        setupGestures()
        applyReadingPreferences()
    }
    
    
    private func setupGestures() {
        // Tap gesture for hiding/showing controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        textView.addGestureRecognizer(tapGesture)
        
        // Pan gesture for brightness adjustment - disabled by default
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.isEnabled = false // Disable until user explicitly enables it
        view.addGestureRecognizer(panGesture)
    }
    
    private func bindViewModel() {
        viewModel.onContentUpdate = { [weak self] in
            self?.updateContent()
            self?.updateChapterInfo()
            
            // Ensure proper scrolling after content update
            // Use stored position on initial load
            DispatchQueue.main.async { [weak self] in
                self?.scrollToCurrentChapter(animated: false, useStoredPosition: true)
            }
        }
        
        viewModel.onProgressUpdate = { [weak self] in
            self?.updateProgress()
        }
        
        viewModel.onPreferencesUpdate = { [weak self] in
            self?.applyReadingPreferences()
        }
    }
    
    // MARK: - Actions
    
    @objc private func dismissTapped() {
        viewModel.saveProgress()
        dismiss(animated: true)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = BookReaderSettingsViewController(preferences: viewModel.preferences)
        settingsVC.delegate = self
        
        if #available(iOS 15.0, *) {
            if let sheet = settingsVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.selectedDetentIdentifier = .medium
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
        }
        
        present(settingsVC, animated: true)
    }
    
    @objc private func previousChapterTapped() {
        stopSpeech()
        stopAutoScroll()
        
        isNavigatingChapter = true
        viewModel.goToPreviousChapter()
        
        // Update UI immediately
        updateChapterInfo()
        
        // Scroll to the new chapter
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCurrentChapter(animated: true)
            // Re-enable scroll detection after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isNavigatingChapter = false
            }
        }
    }
    
    @objc private func nextChapterTapped() {
        stopSpeech()
        stopAutoScroll()
        
        isNavigatingChapter = true
        viewModel.goToNextChapter()
        
        // Update UI immediately
        updateChapterInfo()
        
        // Scroll to the new chapter
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCurrentChapter(animated: true)
            // Re-enable scroll detection after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isNavigatingChapter = false
            }
        }
    }
    
    private func updateChapterInfo() {
        chapterLabel.text = viewModel.currentChapterTitle
        updateNavigationButtons()
        updateProgress()
    }
    
    @objc private func playPauseTapped() {
        if autoScrollTimer != nil {
            stopAutoScroll()
        } else {
            startAutoScroll()
        }
    }
    
    @objc private func bookmarkTapped() {
        viewModel.toggleBookmark()
        updateBookmarkButton()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        toggleUIVisibility()
    }
    
    
    // Auto scroll functionality
    private func startAutoScroll() {
        let speed = Double(viewModel.preferences.autoScrollSpeed ?? 50.0)
        let interval = 1.0 / speed
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentOffset = self.textView.contentOffset.y
            let newOffset = currentOffset + 1
            
            if newOffset < self.textView.contentSize.height - self.textView.bounds.height {
                self.textView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
            } else {
                self.stopAutoScroll()
                if self.viewModel.canGoNext {
                    self.viewModel.goToNextChapter()
                    self.startAutoScroll()
                }
            }
        }
        
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Disabled - brightness now controlled through settings
    }
    
    // MARK: - UI Updates
    
    
    private func scrollToCurrentChapter(animated: Bool, useStoredPosition: Bool = false) {
        guard viewModel.currentChapterIndex < chapterStartPositions.count else { return }
        guard viewModel.currentChapterIndex < viewModel.book.chapters.count else { return }
        
        // If we haven't laid out yet, delay the scroll
        if textView.contentSize.height <= 0 || chapterStartPositions.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.scrollToCurrentChapter(animated: animated, useStoredPosition: useStoredPosition)
            }
            return
        }
        
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // Get the character position for the start of the current chapter
        let chapterStartPosition = chapterStartPositions[viewModel.currentChapterIndex]
        
        // Ensure we have valid text range
        guard chapterStartPosition < textView.text.count else { return }
        
        // Force layout of the entire text view first
        layoutManager.ensureLayout(for: textContainer)
        
        // Calculate chapter bounds
        let chapterEndPosition: Int
        if viewModel.currentChapterIndex < chapterStartPositions.count - 1 {
            chapterEndPosition = chapterStartPositions[viewModel.currentChapterIndex + 1]
        } else {
            chapterEndPosition = textView.text.count
        }
        let chapterLength = chapterEndPosition - chapterStartPosition
        
        // Calculate target position
        let targetCharPosition: Int
        if useStoredPosition && viewModel.preferences.scrollPosition > 0 {
            // Use stored scroll position within the chapter
            targetCharPosition = chapterStartPosition + Int(Double(chapterLength) * viewModel.preferences.scrollPosition)
        } else {
            // Default to chapter start
            targetCharPosition = chapterStartPosition
        }
        
        // Get the glyph range for the target position
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: targetCharPosition, length: 1), actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // Calculate the target offset - account for text container insets
        let yOffset = rect.origin.y - textView.textContainerInset.top
        let maxOffset = max(0, textView.contentSize.height - textView.bounds.height)
        let targetOffset = CGPoint(x: 0, y: min(max(0, yOffset), maxOffset))
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.textView.setContentOffset(targetOffset, animated: false)
            }) { _ in
                // Only reset position if we're navigating chapters
                if !useStoredPosition {
                    self.viewModel.updateScrollPosition(0)
                }
            }
        } else {
            textView.setContentOffset(targetOffset, animated: false)
            // Only reset position if we're navigating chapters
            if !useStoredPosition {
                viewModel.updateScrollPosition(0)
            }
        }
    }
    
    private func restoreReadingPosition() {
        // Only restore position once
        guard !hasRestoredPosition else { return }
        
        // Ensure text view is ready
        guard textView.contentSize.height > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.restoreReadingPosition()
            }
            return
        }
        
        hasRestoredPosition = true
        
        // Calculate position based on overall book progress
        let totalHeight = textView.contentSize.height
        let viewHeight = textView.bounds.height
        let maxScrollY = max(0, totalHeight - viewHeight)
        
        // Use the book's reading progress to determine scroll position
        let targetY = viewModel.readingProgress * maxScrollY
        
        AppLogger.ui.info("Restoring book position", metadata: [
            "readingProgress": viewModel.readingProgress,
            "targetY": targetY,
            "maxScrollY": maxScrollY,
            "currentChapter": viewModel.currentChapterIndex
        ])
        
        // Scroll to the calculated position
        textView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
    }
    
    private func updateProgress() {
        progressView.progress = Float(viewModel.readingProgress)
        percentageLabel.text = "\(Int(viewModel.readingProgress * 100))%"
        readingTimeLabel.text = formatReadingTime(viewModel.totalReadingTime)
    }
    
    private func updateNavigationButtons() {
        previousChapterButton.isEnabled = viewModel.canGoPrevious
        nextChapterButton.isEnabled = viewModel.canGoNext
        previousChapterButton.alpha = viewModel.canGoPrevious ? 1.0 : 0.3
        nextChapterButton.alpha = viewModel.canGoNext ? 1.0 : 0.3
    }
    
    private func updateBookmarkButton() {
        let imageName = viewModel.hasBookmarkAtCurrentPosition ? "bookmark.fill" : "bookmark"
        bookmarkButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    
    private func toggleUIVisibility() {
        controlsHidden = !controlsHidden
        
        UIView.animate(withDuration: 0.3) {
            if self.controlsHidden {
                self.headerView.transform = CGAffineTransform(translationX: 0, y: -self.headerView.bounds.height)
                self.bottomToolbar.transform = CGAffineTransform(translationX: 0, y: self.bottomToolbar.bounds.height)
            } else {
                self.headerView.transform = .identity
                self.bottomToolbar.transform = .identity
            }
        }
    }
    
    // Removed toggleSettingsPanel - now using sheet presentation
    
    // MARK: - Reading Timer
    
    private func startReadingTimer() {
        readingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.viewModel.incrementReadingTime()
        }
    }
    
    private func stopReadingTimer() {
        readingTimer?.invalidate()
        readingTimer = nil
    }
    
    // MARK: - Text-to-Speech
    
    private func startSpeech() {
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
            speechSynthesizer?.delegate = self
        }
        
        let utterance = AVSpeechUtterance(string: viewModel.currentContent)
        utterance.rate = viewModel.preferences.ttsSpeed
        
        if let voice = viewModel.preferences.ttsVoice {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voice)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        speechSynthesizer?.speak(utterance)
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
    
    private func pauseSpeech() {
        speechSynthesizer?.pauseSpeaking(at: .immediate)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    private func stopSpeech() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    // MARK: - Helpers
    
    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func createPapyrusTexture() {
        // Create a subtle papyrus texture pattern
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Background
        context.setFillColor(UIColor(hex: "#F5E6D3")?.cgColor ?? UIColor.systemBackground.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Add subtle texture lines
        context.setStrokeColor(UIColor(hex: "#E5D6C3")?.withAlphaComponent(0.3).cgColor ?? UIColor.gray.cgColor)
        context.setLineWidth(0.5)
        
        for i in stride(from: 0, to: 100, by: 5) {
            let startX = CGFloat.random(in: 0...5)
            let endX = CGFloat.random(in: 95...100)
            context.move(to: CGPoint(x: startX, y: CGFloat(i)))
            context.addLine(to: CGPoint(x: endX, y: CGFloat(i) + CGFloat.random(in: -2...2)))
            context.strokePath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        papyrusBackgroundView.image = image
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyReadingPreferences()
        }
    }
}

// MARK: - UITextViewDelegate

extension BookReaderViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > 0 else { return }
        guard !isNavigatingChapter else { return } // Don't update chapter during navigation
        guard hasRestoredPosition else { return } // Don't update position during initial restore
        
        // Calculate overall book position based on scroll
        let currentY = scrollView.contentOffset.y
        let totalHeight = scrollView.contentSize.height - scrollView.bounds.height
        let overallProgress = totalHeight > 0 ? currentY / totalHeight : 0
        let clampedOverallProgress = max(0, min(1, overallProgress))
        
        // Calculate current position in the text
        let currentOffset = scrollView.contentOffset.y + scrollView.bounds.height / 2
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // Find the character index at the current scroll position
        let point = CGPoint(x: textView.bounds.midX, y: currentOffset)
        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // Find which chapter we're in based on character position
        var currentChapter = 0
        for (index, startPosition) in chapterStartPositions.enumerated() {
            if characterIndex >= startPosition {
                currentChapter = index
            } else {
                break
            }
        }
        
        // Update chapter if changed
        if currentChapter != viewModel.currentChapterIndex && currentChapter < viewModel.book.chapters.count {
            viewModel.currentChapterIndex = currentChapter
            chapterLabel.text = "Chapter \(currentChapter + 1) of \(viewModel.book.chapters.count): \(viewModel.currentChapterTitle)"
            updateChapterInfo()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        // Calculate progress within current chapter for scroll position tracking
        if currentChapter < chapterStartPositions.count {
            let chapterStart = chapterStartPositions[currentChapter]
            let chapterEnd: Int
            
            if currentChapter < chapterStartPositions.count - 1 {
                chapterEnd = chapterStartPositions[currentChapter + 1]
            } else {
                chapterEnd = textView.text.count
            }
            
            let chapterLength = chapterEnd - chapterStart
            if chapterLength > 0 {
                let progressInChapter = Double(characterIndex - chapterStart) / Double(chapterLength)
                let clampedProgress = max(0, min(1, progressInChapter))
                
                // Update both chapter scroll position and overall book progress
                viewModel.updateScrollPosition(clampedProgress)
                viewModel.updateOverallProgress(clampedOverallProgress)
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BookReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension BookReaderViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        
        // Auto-advance to next chapter if available
        if viewModel.canGoNext {
            viewModel.goToNextChapter()
            startSpeech()
        }
    }
}

// MARK: - BookReaderSettingsDelegate

extension BookReaderViewController: BookReaderSettingsDelegate {
    func settingsDidUpdateFontSize(_ size: Double) {
        viewModel.updateFontSize(size)
    }
    
    func settingsDidUpdateBrightness(_ brightness: Double) {
        viewModel.updateBrightness(brightness)
        view.alpha = CGFloat(brightness)
    }
    
    func settingsDidUpdateTTSSpeed(_ speed: Float) {
        viewModel.updateTTSSpeed(speed)
    }
    
    func settingsDidUpdateAutoScrollSpeed(_ speed: Double) {
        viewModel.updateAutoScrollSpeed(speed)
        // If currently auto-scrolling, restart with new speed
        if autoScrollTimer != nil {
            stopAutoScroll()
            startAutoScroll()
        }
    }
    
    func settingsDidUpdateFontFamily(_ family: String) {
        viewModel.preferences.fontFamily = family
        updateContent()
    }
    
    func settingsDidUpdateFontWeight(_ weight: String) {
        viewModel.preferences.fontWeight = weight
        updateContent()
    }
    
    func settingsDidUpdateLineSpacing(_ spacing: Double) {
        viewModel.preferences.lineSpacing = spacing
        updateContent()
    }
    
    func settingsDidUpdateParagraphSpacing(_ spacing: Double) {
        viewModel.preferences.paragraphSpacing = spacing
        updateContent()
    }
    
    func settingsDidUpdateFirstLineIndent(_ indent: Double) {
        viewModel.preferences.firstLineIndent = indent
        updateContent()
    }
    
    func settingsDidUpdateTextAlignment(_ alignment: String) {
        viewModel.preferences.textAlignment = alignment
        updateContent()
    }
    
    func settingsDidUpdateMargins(_ size: Double) {
        viewModel.preferences.marginSize = size
        applyTextAlignment()
    }
    
    func settingsDidUpdateTheme(_ theme: String) {
        viewModel.preferences.theme = theme
        applyReadingPreferences()
    }
    
    func settingsDidUpdateHyphenation(_ enabled: Bool) {
        viewModel.preferences.enableHyphenation = enabled
        updateContent()
    }
    
    func settingsDidUpdatePageProgress(_ enabled: Bool) {
        viewModel.preferences.showPageProgress = enabled
        progressView.isHidden = !enabled
        percentageLabel.isHidden = !enabled
    }
    
    func settingsDidUpdateKeepScreenOn(_ enabled: Bool) {
        viewModel.preferences.keepScreenOn = enabled
        UIApplication.shared.isIdleTimerDisabled = enabled
    }
    
    func settingsDidUpdateSwipeGestures(_ enabled: Bool) {
        viewModel.preferences.enableSwipeGestures = enabled
        // Handle swipe gesture enabling/disabling
    }
    
    func settingsDidUpdatePageTransition(_ style: String) {
        viewModel.preferences.pageTransitionStyle = style
        // Handle page transition style change
    }
}

// MARK: - Text Selection and Highlights

extension BookReaderViewController {
    
    private func setupTextSelection() {
        textSelectionHandler = BookReaderTextSelectionHandler(textView: textView)
        textSelectionHandler?.delegate = self
        textSelectionHandler?.configureTextView()
        
        // Set the selection handler on the text view
        textView.selectionHandler = textSelectionHandler
    }
    
    private func loadHighlights() {
        Task {
            do {
                let user = try await AuthenticationManager.shared.getCurrentUser()
                currentHighlights = try DatabaseManager.shared.getBookHighlights(
                    userId: user.id,
                    bookId: viewModel.book.id
                )
                applyHighlights()
            } catch {
                AppLogger.database.error("Failed to load highlights: \(error)")
            }
        }
    }
    
    private func applyHighlights() {
        // Remove existing highlight views
        highlightViews.forEach { $0.removeFromSuperview() }
        highlightViews.removeAll()
        
        // Apply new highlights to the text
        guard let attributedText = textView.attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        for highlight in currentHighlights {
            let range = NSRange(location: highlight.startPosition, length: highlight.endPosition - highlight.startPosition)
            
            // Skip if range is invalid
            guard range.location + range.length <= mutableText.length else { continue }
            
            // Apply highlight color
            let color = UIColor(hex: highlight.color) ?? UIColor(hex: viewModel.preferences.highlightColor) ?? UIColor.yellow.withAlphaComponent(0.3)
            mutableText.addAttribute(.backgroundColor, value: color, range: range)
        }
        
        textView.attributedText = mutableText
    }
    
    private func saveHighlight(text: String, range: NSRange, color: UIColor, note: String? = nil, oracleConsultationId: String? = nil) {
        Task {
            do {
                let user = try await AuthenticationManager.shared.getCurrentUser()
                
                // Find which chapter this highlight belongs to
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
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
            } catch {
                AppLogger.database.error("Failed to save highlight: \(error)")
            }
        }
    }
    
    private func showOracleExplanation(for text: String, range: NSRange) {
        // Get book context (surrounding text)
        let contextRange = NSRange(
            location: max(0, range.location - 100),
            length: min(textView.text.count - range.location, range.length + 200)
        )
        let context = (textView.text as NSString).substring(with: contextRange)
        
        // Get current deity
        let deityId = viewModel.preferences.ttsVoice ?? "thoth" // Default to Thoth if no deity selected
        
        // Show oracle explanation view
        let oracleView = OracleTextExplanationView(
            selectedText: text,
            bookContext: context,
            deityId: deityId
        )
        oracleView.delegate = self
        oracleView.show(in: view)
    }
    
    private func shareText(_ text: String) {
        let activityVC = UIActivityViewController(
            activityItems: [text, "From \"\(viewModel.book.title)\" in App of the Dead"],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = textView
            popover.sourceRect = textView.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func showNoteEditor(for text: String, range: NSRange) {
        let alert = UIAlertController(title: "Add Note", message: "Add a note for this highlighted text", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter your note..."
            textField.autocapitalizationType = .sentences
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let note = alert.textFields?.first?.text, !note.isEmpty {
                self?.saveHighlight(text: text, range: range, color: PapyrusDesignSystem.Colors.goldLeaf, note: note)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func applyReadingPreferences() {
        // Apply theme
        applyTheme(viewModel.preferences.theme)
        
        // Apply brightness
        view.alpha = CGFloat(viewModel.preferences.brightness)
        
        // Apply other preferences
        applyTextAlignment()
        
        // Keep screen on if enabled
        UIApplication.shared.isIdleTimerDisabled = viewModel.preferences.keepScreenOn
        
        updateContent()
    }
    
    private func applyTheme(_ themeName: String) {
        guard let theme = ReadingTheme.themes[themeName] else { return }
        
        // Apply theme colors
        view.backgroundColor = theme.backgroundColor
        textView.backgroundColor = .clear
        textView.textColor = theme.textColor
        
        // Update UI elements
        headerView.backgroundColor = theme.isDark ? theme.backgroundColor : PapyrusDesignSystem.Colors.beige
        bottomToolbar.backgroundColor = theme.isDark ? theme.backgroundColor : PapyrusDesignSystem.Colors.beige
        
        // Update control colors
        let controlTint = theme.isDark ? theme.textColor : PapyrusDesignSystem.Colors.ancientInk
        backButton.tintColor = controlTint
        settingsButton.tintColor = controlTint
        previousChapterButton.tintColor = controlTint
        nextChapterButton.tintColor = controlTint
        bookmarkButton.tintColor = controlTint
        playPauseButton.tintColor = theme.isDark ? theme.highlightColor : PapyrusDesignSystem.Colors.goldLeaf
        
        // Update labels
        titleLabel.textColor = controlTint
        chapterLabel.textColor = theme.secondaryTextColor
        readingTimeLabel.textColor = theme.secondaryTextColor
        percentageLabel.textColor = theme.secondaryTextColor
        
        // Update papyrus background
        papyrusBackgroundView.alpha = theme.isDark ? 0.05 : 0.3
    }
    
    private func applyTextAlignment() {
        let margin = CGFloat(viewModel.preferences.marginSize)
        textView.textContainerInset = UIEdgeInsets(top: 120, left: margin, bottom: 100, right: margin)
        updateContent()
    }
    
    private func updateContent() {
        chapterStartPositions.removeAll()
        
        let attributedString = NSMutableAttributedString()
        
        // Create font based on preferences including weight
        let font = getFont()
        
        // Create paragraph style
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
        
        // Build full content with chapter markers
        for chapter in viewModel.book.chapters {
            // Record chapter start position
            chapterStartPositions.append(attributedString.length)
            
            // Add chapter title
            let titleFont = getFont(size: viewModel.preferences.fontSize + 6, weight: .bold)
            let chapterTitle = NSMutableAttributedString(string: "\(chapter.title)\n\n", attributes: [
                .font: titleFont,
                .foregroundColor: theme.textColor,
                .paragraphStyle: paragraphStyle
            ])
            attributedString.append(chapterTitle)
            
            // Add chapter content
            let chapterContent = NSAttributedString(string: chapter.content + "\n\n\n", attributes: baseAttributes)
            attributedString.append(chapterContent)
        }
        
        textView.attributedText = attributedString
        
        // Apply any highlights
        applyHighlights()
    }
    
    private func getFont(size: CGFloat? = nil, weight: UIFont.Weight? = nil) -> UIFont {
        let fontSize = CGFloat(size ?? viewModel.preferences.fontSize)
        let fontWeight = weight ?? getFontWeight()
        
        if let customFont = UIFont(name: viewModel.preferences.fontFamily, size: fontSize) {
            // For custom fonts, we need to get the appropriate weight variant
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

// MARK: - BookReaderTextSelectionDelegate

extension BookReaderViewController: BookReaderTextSelectionDelegate {
    func textSelectionHandler(_ handler: BookReaderTextSelectionHandler, didSelectAction action: TextSelectionAction, text: String, range: NSRange) {
        switch action {
        case .askOracle:
            showOracleExplanation(for: text, range: range)
            
        case .highlight(let color):
            saveHighlight(text: text, range: range, color: color)
            
        case .addNote:
            showNoteEditor(for: text, range: range)
            
        case .copy:
            UIPasteboard.general.string = text
            
        case .share:
            shareText(text)
            
        case .define:
            // iOS handles this automatically
            break
        }
    }
}

// MARK: - OracleTextExplanationViewDelegate

extension BookReaderViewController: OracleTextExplanationViewDelegate {
    func oracleTextExplanationViewDidDismiss(_ view: OracleTextExplanationView) {
        // Handle dismissal if needed
    }
    
    func oracleTextExplanationView(_ view: OracleTextExplanationView, didSaveExplanation explanation: String, for text: String) {
        // Find the range of the text in the current view
        if let range = textView.text.range(of: text) {
            let nsRange = NSRange(range, in: textView.text)
            
            // Save oracle consultation
            Task {
                do {
                    let user = try await AuthenticationManager.shared.getCurrentUser()
                    
                    // Save oracle consultation
                    let consultation = OracleConsultation(
                        userId: user.id,
                        deityId: viewModel.preferences.ttsVoice ?? "thoth"
                    )
                    
                    try DatabaseManager.shared.saveOracleConsultation(consultation)
                    
                    // Save highlight with oracle consultation
                    saveHighlight(
                        text: text,
                        range: nsRange,
                        color: PapyrusDesignSystem.Colors.goldLeaf,
                        note: nil,
                        oracleConsultationId: consultation.id
                    )
                    
                } catch {
                    AppLogger.database.error("Failed to save oracle consultation: \(error)")
                }
            }
        }
    }
}

// Helper extension for UIColor
extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format: "#%06x", rgb)
    }
}