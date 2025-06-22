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
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.showsVerticalScrollIndicator = false
        textView.delegate = self
        return textView
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
    
    // Settings Panel
    private lazy var settingsPanel: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: -4)
        view.layer.shadowRadius = 8
        view.isHidden = true
        return view
    }()
    
    private lazy var fontSizeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 14
        slider.maximumValue = 28
        slider.value = 18
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(fontSizeChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.3
        slider.maximumValue = 1.0
        slider.value = 1.0
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(brightnessChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var ttsSpeedSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 2.0
        slider.value = 1.0
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(ttsSpeedChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var autoScrollSpeedSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 10
        slider.maximumValue = 100
        slider.value = 50
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(autoScrollSpeedChanged(_:)), for: .valueChanged)
        return slider
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
        bindViewModel()
        startReadingTimer()
        
        // Load initial content
        viewModel.loadCurrentChapter()
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
        view.addSubview(textView)
        view.addSubview(headerView)
        view.addSubview(bottomToolbar)
        view.addSubview(settingsPanel)
        
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
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
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
            percentageLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            // Settings Panel
            settingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            settingsPanel.heightAnchor.constraint(equalToConstant: 350)
        ])
        
        setupSettingsPanel()
        setupGestures()
        applyReadingPreferences()
    }
    
    private func setupSettingsPanel() {
        let fontSizeLabel = createSettingLabel("Font Size")
        let brightnessLabel = createSettingLabel("Brightness")
        let ttsSpeedLabel = createSettingLabel("TTS Speed")
        let autoScrollSpeedLabel = createSettingLabel("Auto-Scroll Speed")
        
        let fontStack = UIStackView(arrangedSubviews: [fontSizeLabel, fontSizeSlider])
        fontStack.axis = .vertical
        fontStack.spacing = 8
        
        let brightnessStack = UIStackView(arrangedSubviews: [brightnessLabel, brightnessSlider])
        brightnessStack.axis = .vertical
        brightnessStack.spacing = 8
        
        let ttsStack = UIStackView(arrangedSubviews: [ttsSpeedLabel, ttsSpeedSlider])
        ttsStack.axis = .vertical
        ttsStack.spacing = 8
        
        let autoScrollStack = UIStackView(arrangedSubviews: [autoScrollSpeedLabel, autoScrollSpeedSlider])
        autoScrollStack.axis = .vertical
        autoScrollStack.spacing = 8
        
        let mainStack = UIStackView(arrangedSubviews: [fontStack, brightnessStack, ttsStack, autoScrollStack])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        settingsPanel.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: settingsPanel.topAnchor, constant: 30),
            mainStack.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -20)
        ])
    }
    
    private func createSettingLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = PapyrusDesignSystem.Typography.body()
        label.textColor = PapyrusDesignSystem.Colors.ancientInk
        return label
    }
    
    private func setupGestures() {
        // Tap gesture for hiding/showing controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        textView.addGestureRecognizer(tapGesture)
        
        // Tap gesture for settings panel
        let settingsTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSettingsPanelTap))
        settingsPanel.addGestureRecognizer(settingsTapGesture)
        
        // Pan gesture for brightness adjustment
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    private func bindViewModel() {
        viewModel.onContentUpdate = { [weak self] in
            self?.updateContent()
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
        toggleSettingsPanel()
    }
    
    @objc private func previousChapterTapped() {
        stopSpeech()
        stopAutoScroll()
        
        if viewModel.currentChapterIndex > 0 {
            viewModel.currentChapterIndex -= 1
            viewModel.saveProgress()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            scrollToCurrentChapter(animated: true)
            updateChapterInfo()
        }
    }
    
    @objc private func nextChapterTapped() {
        stopSpeech()
        stopAutoScroll()
        
        if viewModel.currentChapterIndex < viewModel.book.chapters.count - 1 {
            viewModel.currentChapterIndex += 1
            viewModel.saveProgress()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            scrollToCurrentChapter(animated: true)
            updateChapterInfo()
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
    
    @objc private func fontSizeChanged(_ slider: UISlider) {
        viewModel.updateFontSize(Double(slider.value))
    }
    
    @objc private func brightnessChanged(_ slider: UISlider) {
        viewModel.updateBrightness(Double(slider.value))
        view.alpha = CGFloat(slider.value)
    }
    
    @objc private func ttsSpeedChanged(_ slider: UISlider) {
        viewModel.updateTTSSpeed(slider.value)
    }
    
    @objc private func autoScrollSpeedChanged(_ slider: UISlider) {
        viewModel.updateAutoScrollSpeed(Double(slider.value))
        // If currently auto-scrolling, restart with new speed
        if autoScrollTimer != nil {
            stopAutoScroll()
            startAutoScroll()
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if !settingsPanel.isHidden {
            toggleSettingsPanel()
        } else {
            toggleUIVisibility()
        }
    }
    
    @objc private func handleSettingsPanelTap() {
        // Do nothing - prevent settings panel from closing when tapped
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
        switch gesture.state {
        case .began:
            panGestureStartPosition = CGFloat(brightnessSlider.value)
        case .changed:
            let translation = gesture.translation(in: view)
            let change = Float(-translation.y / 200.0)
            let newValue = max(0.3, min(1.0, panGestureStartPosition + CGFloat(change)))
            brightnessSlider.value = Float(newValue)
            brightnessChanged(brightnessSlider)
        default:
            break
        }
    }
    
    // MARK: - UI Updates
    
    private func updateContent() {
        titleLabel.text = viewModel.book.title
        chapterLabel.text = viewModel.currentChapterTitle
        
        // Create combined content from all chapters
        var fullContent = ""
        for (index, chapter) in viewModel.book.chapters.enumerated() {
            if index > 0 {
                fullContent += "\n\n\n"
            }
            fullContent += "Chapter \(chapter.chapterNumber): \(chapter.title)\n\n"
            fullContent += chapter.content
        }
        
        // Create attributed string with proper formatting
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(viewModel.preferences.lineSpacing * viewModel.preferences.fontSize)
        paragraphStyle.alignment = .justified
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: viewModel.preferences.fontFamily, size: viewModel.preferences.fontSize) ?? UIFont.systemFont(ofSize: viewModel.preferences.fontSize),
            .foregroundColor: UIColor(hex: viewModel.preferences.textColor) ?? PapyrusDesignSystem.Colors.primaryText,
            .paragraphStyle: paragraphStyle
        ]
        
        textView.attributedText = NSAttributedString(string: fullContent, attributes: attributes)
        
        // Scroll to current chapter
        DispatchQueue.main.async {
            self.scrollToCurrentChapter(animated: false)
        }
        
        updateNavigationButtons()
        updateBookmarkButton()
    }
    
    private func scrollToCurrentChapter(animated: Bool) {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        var chapterStartPosition = 0
        
        for (index, chapter) in viewModel.book.chapters.enumerated() {
            if index == viewModel.currentChapterIndex {
                break
            }
            // Account for chapter header and content
            chapterStartPosition += "Chapter \(chapter.chapterNumber): \(chapter.title)\n\n".count
            chapterStartPosition += chapter.content.count
            chapterStartPosition += "\n\n\n".count // Space between chapters
        }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: chapterStartPosition)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
        
        textView.setContentOffset(CGPoint(x: 0, y: rect.origin.y - 20), animated: animated)
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
    
    private func applyReadingPreferences() {
        view.backgroundColor = UIColor(hex: viewModel.preferences.backgroundColor) ?? PapyrusDesignSystem.Colors.background
        view.alpha = CGFloat(viewModel.preferences.brightness)
        
        fontSizeSlider.value = Float(viewModel.preferences.fontSize)
        brightnessSlider.value = Float(viewModel.preferences.brightness)
        ttsSpeedSlider.value = viewModel.preferences.ttsSpeed
        autoScrollSpeedSlider.value = Float(viewModel.preferences.autoScrollSpeed ?? 50.0)
        
        updateContent()
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
    
    private func toggleSettingsPanel() {
        if settingsPanel.isHidden {
            settingsPanel.alpha = 0
            settingsPanel.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.settingsPanel.alpha = 1
                self.settingsPanel.transform = CGAffineTransform(translationX: 0, y: -20)
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.settingsPanel.alpha = 0
                self.settingsPanel.transform = .identity
            }) { _ in
                self.settingsPanel.isHidden = true
            }
        }
    }
    
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
}

// MARK: - UITextViewDelegate

extension BookReaderViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let progress = scrollView.contentOffset.y / max(1, scrollView.contentSize.height - scrollView.bounds.height)
        viewModel.updateScrollPosition(Double(progress))
        
        // Check if we've scrolled to a new chapter
        let currentOffset = scrollView.contentOffset.y + scrollView.bounds.height / 2
        var accumulatedHeight: CGFloat = 0
        var newChapterIndex = 0
        
        for (index, chapter) in viewModel.book.chapters.enumerated() {
            let chapterText = "Chapter \(chapter.chapterNumber): \(chapter.title)\n\n\(chapter.content)"
            let chapterHeight = estimatedHeight(for: chapterText)
            
            if currentOffset < accumulatedHeight + chapterHeight {
                newChapterIndex = index
                break
            }
            accumulatedHeight += chapterHeight + 60 // Account for spacing
        }
        
        if newChapterIndex != viewModel.currentChapterIndex {
            viewModel.currentChapterIndex = newChapterIndex
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            updateChapterInfo()
        }
    }
    
    private func estimatedHeight(for text: String) -> CGFloat {
        let textView = UITextView()
        textView.text = text
        textView.font = UIFont(name: viewModel.preferences.fontFamily, size: viewModel.preferences.fontSize) ?? UIFont.systemFont(ofSize: viewModel.preferences.fontSize)
        let size = textView.sizeThatFits(CGSize(width: self.textView.bounds.width - 40, height: CGFloat.greatestFiniteMagnitude))
        return size.height
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