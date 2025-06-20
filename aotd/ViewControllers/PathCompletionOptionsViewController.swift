import UIKit

class PathCompletionOptionsViewController: UIViewController {
    
    private let beliefSystem: BeliefSystem
    private let progress: Progress
    private weak var coordinator: LearningPathCoordinator?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView()
    private let optionsStackView = UIStackView()
    private let masterTestInfoLabel = UILabel()
    
    private let replayButton = UIButton(type: .system)
    private let masterTestButton = UIButton(type: .system)
    
    init(beliefSystem: BeliefSystem, progress: Progress, coordinator: LearningPathCoordinator?) {
        self.beliefSystem = beliefSystem
        self.progress = progress
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateContent()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        titleLabel.font = UIFont(name: "Papyrus", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.Papyrus.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel.font = .systemFont(ofSize: 17, weight: .medium)
        progressLabel.textColor = UIColor.Papyrus.secondaryText
        progressLabel.textAlignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressView.progressTintColor = UIColor(hex: beliefSystem.color)
        progressView.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 12
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        [replayButton, masterTestButton].forEach { button in
            button.configuration = .filled()
            button.configuration?.cornerStyle = .medium
            button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        replayButton.configuration?.baseForegroundColor = UIColor.Papyrus.primaryText
        replayButton.configuration?.baseBackgroundColor = UIColor.Papyrus.cardBackground
        replayButton.addTarget(self, action: #selector(replayTapped), for: .touchUpInside)
        
        masterTestButton.configuration?.title = "Take Master Test"
        masterTestButton.configuration?.image = UIImage(systemName: "crown.fill")
        masterTestButton.configuration?.imagePadding = 8
        masterTestButton.configuration?.baseForegroundColor = .white
        masterTestButton.configuration?.baseBackgroundColor = UIColor(hex: beliefSystem.color)
        masterTestButton.addTarget(self, action: #selector(masterTestTapped), for: .touchUpInside)
        
        masterTestInfoLabel.font = .systemFont(ofSize: 13)
        masterTestInfoLabel.textColor = UIColor.Papyrus.secondaryText
        masterTestInfoLabel.textAlignment = .center
        masterTestInfoLabel.numberOfLines = 0
        masterTestInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.backgroundColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(progressLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(optionsStackView)
        containerView.addSubview(separator)
        containerView.addSubview(masterTestInfoLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            progressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            progressView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            optionsStackView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 30),
            optionsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            optionsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            separator.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            masterTestInfoLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            masterTestInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            masterTestInfoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            masterTestInfoLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func updateContent() {
        let totalXP = beliefSystem.totalXP
        let currentXP = progress.currentXP
        let completionPercentage = min(100, Int((Double(currentXP) / Double(totalXP)) * 100))
        let hasPerfectScore = currentXP >= totalXP
        
        titleLabel.text = "\(beliefSystem.name) Path Complete! 🎉"
        
        // More informative progress text
        if hasPerfectScore {
            progressLabel.text = "Perfect Score! \(currentXP) XP earned"
        } else {
            let missedXP = totalXP - currentXP
            progressLabel.text = "\(completionPercentage)% complete • \(missedXP) XP available to earn"
        }
        
        progressView.progress = Float(currentXP) / Float(totalXP)
        
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Configure replay button text based on score
        if hasPerfectScore {
            replayButton.configuration?.title = "Practice Again"
        } else {
            replayButton.configuration?.title = "Review & Improve Score"
        }
        
        optionsStackView.addArrangedSubview(replayButton)
        
        let canTakeMasterTest = completionPercentage >= 80
        if canTakeMasterTest {
            optionsStackView.addArrangedSubview(masterTestButton)
            if progress.status == .mastered {
                masterTestButton.configuration?.title = "Retake Master Test"
                masterTestInfoLabel.text = "You've mastered this path! 🏆"
            } else {
                masterTestInfoLabel.text = "Master Test unlocked! Score 80% or higher to earn the crown badge."
            }
        } else {
            let xpNeeded = Int(ceil(Double(totalXP) * 0.8)) - currentXP
            masterTestInfoLabel.text = "Earn \(xpNeeded) more XP to unlock the Master Test (\(80 - completionPercentage)% to go)"
        }
    }
    
    @objc private func replayTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.coordinator?.startLearningPath(for: self.beliefSystem, replay: true)
        }
    }
    
    @objc private func masterTestTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.coordinator?.startMasterTest(for: self.beliefSystem)
        }
    }
}