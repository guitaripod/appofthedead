import UIKit
import AVFoundation

final class BookReaderViewController: UIViewController {
    
    
    
    let viewModel: BookReaderViewModel
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var readingTimer: Timer?
    private var panGestureStartPosition: CGFloat = 0
    private var autoScrollTimer: Timer?
    var controlsHidden = false
    private var isNavigatingChapter = false
    private var hasRestoredPosition = false
    private var textSelectionHandler: BookReaderTextSelectionHandler?
    private var currentHighlights: [BookHighlight] = []
    private var highlightViews: [UIView] = []
    private var chapterStartPositions: [Int] = []
    
    
    
    lazy var headerView: UIView = {
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
    
    lazy var textView: BookReaderTextView = {
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
    
    lazy var bottomToolbar: UIView = {
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
    
    lazy var playPauseButton: UIButton = {
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
        
        // iPad-specific layout enhancements
        updateLayoutForIPad()
        
        
        viewModel.loadCurrentChapter()
        
        
        loadHighlights()
        
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSpeech()
        stopReadingTimer()
        viewModel.saveAll() 
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: viewModel.preferences.backgroundColor) ?? PapyrusDesignSystem.Colors.background
        
        
        view.addSubview(papyrusBackgroundView)
        view.addSubview(textView)
        view.addSubview(headerView)
        view.addSubview(bottomToolbar)
        
        
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
            
            papyrusBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            papyrusBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            papyrusBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            papyrusBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            
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
            
            
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        textView.addGestureRecognizer(tapGesture)
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.isEnabled = false 
        view.addGestureRecognizer(panGesture)
    }
    
    private func bindViewModel() {
        viewModel.onContentUpdate = { [weak self] in
            self?.updateContent()
            self?.updateChapterInfo()
            
            
            
            DispatchQueue.main.async { [weak self] in
                self?.scrollToCurrentChapter(animated: false, useStoredPosition: true)
                
                self?.hasRestoredPosition = true
                
                self?.updateProgress()
            }
        }
        
        viewModel.onProgressUpdate = { [weak self] in
            self?.updateProgress()
        }
        
        viewModel.onPreferencesUpdate = { [weak self] in
            self?.applyReadingPreferences()
        }
    }
    
    
    
    @objc private func dismissTapped() {
        viewModel.saveAll() 
        dismiss(animated: true)
    }
    
    @objc private func appWillResignActive() {
        viewModel.saveAll() 
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
    
    @objc func previousChapterTapped() {
        stopSpeech()
        stopAutoScroll()
        
        isNavigatingChapter = true
        viewModel.goToPreviousChapter()
        
        
        updateChapterInfo()
        
        
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCurrentChapter(animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isNavigatingChapter = false
            }
        }
    }
    
    @objc func nextChapterTapped() {
        stopSpeech()
        stopAutoScroll()
        
        isNavigatingChapter = true
        viewModel.goToNextChapter()
        
        
        updateChapterInfo()
        
        
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCurrentChapter(animated: true)
            
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
        
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        toggleUIVisibility()
    }
    
    
    
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
        
    }
    
    
    
    
    private func scrollToCurrentChapter(animated: Bool, useStoredPosition: Bool = false) {
        guard viewModel.currentChapterIndex < chapterStartPositions.count else { return }
        guard viewModel.currentChapterIndex < viewModel.book.chapters.count else { return }
        
        
        if textView.contentSize.height <= 0 || chapterStartPositions.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.scrollToCurrentChapter(animated: animated, useStoredPosition: useStoredPosition)
            }
            return
        }
        
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        
        let chapterStartPosition = chapterStartPositions[viewModel.currentChapterIndex]
        
        
        guard chapterStartPosition < textView.text.count else { return }
        
        
        layoutManager.ensureLayout(for: textContainer)
        
        
        let chapterEndPosition: Int
        if viewModel.currentChapterIndex < chapterStartPositions.count - 1 {
            chapterEndPosition = chapterStartPositions[viewModel.currentChapterIndex + 1]
        } else {
            chapterEndPosition = textView.text.count
        }
        let chapterLength = chapterEndPosition - chapterStartPosition
        
        
        let targetCharPosition: Int
        if useStoredPosition && viewModel.preferences.scrollPosition > 0 {
            
            targetCharPosition = chapterStartPosition + Int(Double(chapterLength) * viewModel.preferences.scrollPosition)
        } else {
            
            targetCharPosition = chapterStartPosition
        }
        
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: targetCharPosition, length: 1), actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        
        let yOffset = rect.origin.y - textView.textContainerInset.top
        let maxOffset = max(0, textView.contentSize.height - textView.bounds.height)
        let targetOffset = CGPoint(x: 0, y: min(max(0, yOffset), maxOffset))
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.textView.setContentOffset(targetOffset, animated: false)
            }) { _ in
                
                if !useStoredPosition {
                    self.viewModel.updateScrollPosition(0)
                }
            }
        } else {
            textView.setContentOffset(targetOffset, animated: false)
            
            if !useStoredPosition {
                viewModel.updateScrollPosition(0)
            }
        }
    }
    
    private func restoreReadingPosition() {
        
        guard !hasRestoredPosition else { return }
        
        
        guard textView.contentSize.height > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.restoreReadingPosition()
            }
            return
        }
        
        hasRestoredPosition = true
        
        
        let totalHeight = textView.contentSize.height
        let viewHeight = textView.bounds.height
        let maxScrollY = max(0, totalHeight - viewHeight)
        
        
        let targetY = viewModel.readingProgress * maxScrollY
        
        
        textView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
    }
    
    private func updateProgress() {
        progressView.progress = Float(viewModel.readingProgress)
        percentageLabel.text = "\(Int(viewModel.readingProgress * 100))%"
        
        
        let timeRemaining = calculateTimeRemaining()
        if timeRemaining > 0 {
            readingTimeLabel.text = "~\(formatReadingTime(timeRemaining)) left"
        } else {
            
            if viewModel.readingProgress > 0.95 {
                readingTimeLabel.text = "Almost done!"
            } else if viewModel.totalReadingTime < 60 {
                
                readingTimeLabel.text = "Reading \(formatReadingTime(viewModel.totalReadingTime))"
            } else {
                readingTimeLabel.text = "Calculating..."
            }
        }
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
    
    
    
    
    
    private func startReadingTimer() {
        readingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.viewModel.incrementReadingTime()
        }
    }
    
    private func stopReadingTimer() {
        readingTimer?.invalidate()
        readingTimer = nil
    }
    
    
    
    private func startSpeech() {
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
            speechSynthesizer?.delegate = self
        }
        
        let utterance = AVSpeechUtterance(string: viewModel.currentContent)
        utterance.rate = Float(viewModel.preferences.ttsSpeed)
        
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
    
    private func calculateTimeRemaining() -> TimeInterval {
        
        guard viewModel.totalReadingTime > 60 else { return 0 }
        guard viewModel.readingProgress > 0.01 else { return 0 }
        
        
        let timePerProgress = viewModel.totalReadingTime / viewModel.readingProgress
        
        
        let remainingProgress = 1.0 - viewModel.readingProgress
        
        
        let estimatedTimeRemaining = remainingProgress * timePerProgress
        
        
        return min(estimatedTimeRemaining, 36000)
    }
    
    private func createPapyrusTexture() {
        
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        
        context.setFillColor(UIColor(hex: "#F5E6D3")?.cgColor ?? UIColor.systemBackground.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        
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
        
        // Update layout for iPad when size classes change
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
           traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            updateLayoutForIPad()
        }
    }
}



extension BookReaderViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > 0 else { return }
        guard !isNavigatingChapter else { return } 
        guard hasRestoredPosition else { return } 
        
        
        
        
        
        let currentOffset = scrollView.contentOffset.y + scrollView.bounds.height / 2
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        
        let point = CGPoint(x: textView.bounds.midX, y: currentOffset)
        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        
        var currentChapter = 0
        for (index, startPosition) in chapterStartPositions.enumerated() {
            if characterIndex >= startPosition {
                currentChapter = index
            } else {
                break
            }
        }
        
        
        if currentChapter != viewModel.currentChapterIndex && currentChapter < viewModel.book.chapters.count {
            viewModel.updateCurrentChapter(currentChapter)
            chapterLabel.text = "Chapter \(currentChapter + 1) of \(viewModel.book.chapters.count): \(viewModel.currentChapterTitle)"
            updateChapterInfo()
            
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        
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
                
                
                viewModel.updateScrollPosition(clampedProgress)
                
                
                
            }
        }
    }
}



extension BookReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}



extension BookReaderViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        
        
        if viewModel.canGoNext {
            viewModel.goToNextChapter()
            startSpeech()
        }
    }
}



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
        
    }
    
    func settingsDidUpdatePageTransition(_ style: String) {
        viewModel.preferences.pageTransitionStyle = style
        
    }
}



extension BookReaderViewController {
    
    private func setupTextSelection() {
        textSelectionHandler = BookReaderTextSelectionHandler(textView: textView)
        textSelectionHandler?.delegate = self
        textSelectionHandler?.configureTextView()
        
        
        textView.selectionHandler = textSelectionHandler
    }
    
    private func loadHighlights() {
        Task {
            do {
                guard let user = DatabaseManager.shared.fetchUser() else { return }
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
    
    private func saveHighlight(text: String, range: NSRange, color: UIColor, note: String? = nil, oracleConsultationId: String? = nil) {
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
                AppLogger.database.error("Failed to save highlight: \(error)")
            }
        }
    }
    
    private func showOracleExplanation(for text: String, range: NSRange) {
        
        let contextRange = NSRange(
            location: max(0, range.location - 100),
            length: min(textView.text.count - range.location, range.length + 200)
        )
        let context = (textView.text as NSString).substring(with: contextRange)
        
        
        let deityId = viewModel.preferences.ttsVoice ?? "thoth" 
        
        
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
        playPauseButton.tintColor = theme.isDark ? theme.highlightColor : PapyrusDesignSystem.Colors.goldLeaf
        
        
        titleLabel.textColor = controlTint
        chapterLabel.textColor = theme.secondaryTextColor
        readingTimeLabel.textColor = theme.secondaryTextColor
        percentageLabel.textColor = theme.secondaryTextColor
        
        
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
            
            break
        }
    }
}



extension BookReaderViewController: OracleTextExplanationViewDelegate {
    func oracleTextExplanationViewDidDismiss(_ view: OracleTextExplanationView) {
        
    }
    
    func oracleTextExplanationView(_ view: OracleTextExplanationView, didSaveExplanation explanation: String, for text: String) {
        
        if let range = textView.text.range(of: text) {
            let nsRange = NSRange(range, in: textView.text)
            
            
            Task {
                do {
                guard let user = DatabaseManager.shared.fetchUser() else { return }
                    
                    
                    let consultation = OracleConsultation(
                        userId: user.id,
                        deityId: viewModel.preferences.ttsVoice ?? "thoth"
                    )
                    
                    try DatabaseManager.shared.saveOracleConsultation(consultation)
                    
                    
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