import UIKit

protocol MistakeReviewViewControllerDelegate: AnyObject {
    func mistakeReviewCompleted(correctCount: Int, totalCount: Int, xpEarned: Int)
    func mistakeReviewCancelled()
}

final class MistakeReviewViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: MistakeReviewViewControllerDelegate?
    
    private let beliefSystem: BeliefSystem
    private let mistakes: [Mistake]
    private let session: MistakeSession
    private let contentLoader: ContentLoader
    
    private var currentQuestionIndex = 0
    private var correctCount = 0
    private var questions: [Question] = []
    private var questionToMistakeMap: [String: Mistake] = [:]
    
    // MARK: - UI Elements
    
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        view.progressTintColor = UIColor(hex: beliefSystem.color) ?? UIColor.Papyrus.gold
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Mistake Review"
        if let papyrusFont = UIFont(name: "Papyrus", size: 24) {
            label.font = papyrusFont
        } else {
            label.font = .systemFont(ofSize: 24, weight: .bold)
        }
        label.textColor = UIColor.Papyrus.primaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(beliefSystem.name) • \(mistakes.count) mistakes"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Papyrus.secondaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    init(beliefSystem: BeliefSystem, mistakes: [Mistake], session: MistakeSession, contentLoader: ContentLoader) {
        self.beliefSystem = beliefSystem
        self.mistakes = mistakes
        self.session = session
        self.contentLoader = contentLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadQuestions()
        showNextQuestion()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        // Navigation
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Layout
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(subtitleLabel)
        headerStackView.addArrangedSubview(progressView)
        
        view.addSubview(headerStackView)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            // Header
            headerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Progress view height
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            // Container
            containerView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 30),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadQuestions() {
        // Load all questions from belief system lessons
        let allQuestions = beliefSystem.lessons.flatMap { $0.questions }
        
        // Build question to mistake mapping and filter questions
        questionToMistakeMap.removeAll()
        questions = mistakes.compactMap { mistake in
            if let question = allQuestions.first(where: { $0.id == mistake.questionId }) {
                questionToMistakeMap[question.id] = mistake
                return question
            }
            return nil
        }
        
        // Shuffle for variety
        questions.shuffle()
        
        AppLogger.learning.info("Loaded questions for mistake review", metadata: [
            "mistakeCount": mistakes.count,
            "questionCount": questions.count,
            "mappingCount": questionToMistakeMap.count
        ])
    }
    
    // MARK: - Question Flow
    
    private func showNextQuestion() {
        guard currentQuestionIndex < questions.count else {
            completeReview()
            return
        }
        
        let question = questions[currentQuestionIndex]
        guard let mistake = questionToMistakeMap[question.id] else {
            AppLogger.logError(
                NSError(domain: "MistakeReview", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mistake found for question"]),
                context: "showNextQuestion",
                logger: AppLogger.learning
            )
            currentQuestionIndex += 1
            showNextQuestion()
            return
        }
        
        // Update progress
        let progress = Float(currentQuestionIndex) / Float(questions.count)
        progressView.setProgress(progress, animated: true)
        
        // Create appropriate view controller
        let viewController = createViewController(for: question, mistake: mistake)
        
        // Clear container and add new view controller
        containerView.subviews.forEach { $0.removeFromSuperview() }
        children.forEach { $0.removeFromParent() }
        
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        viewController.didMove(toParent: self)
    }
    
    private func createViewController(for question: Question, mistake: Mistake) -> BaseQuestionViewController {
        let viewModel: BaseQuestionViewModel
        let viewController: BaseQuestionViewController
        
        switch question.type {
        case .multipleChoice:
            viewModel = MultipleChoiceViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = MultipleChoiceViewController(viewModel: viewModel)
            
        case .trueFalse:
            viewModel = BaseQuestionViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = TrueFalseViewController(viewModel: viewModel)
            
        case .matching:
            // For now, use multiple choice as placeholder
            viewModel = MultipleChoiceViewModel(
                question: question,
                beliefSystem: beliefSystem,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.count
            )
            viewController = MultipleChoiceViewController(viewModel: viewModel)
        }
        
        viewModel.delegate = self
        
        // Hide the child's progress view and question number since we're showing our own
        viewController.hideProgressView = true
        viewController.hideQuestionNumber = true
        
        return viewController
    }
    
    // MARK: - Completion
    
    private func completeReview() {
        // Update progress to 100%
        progressView.setProgress(1.0, animated: true)
        
        // Calculate XP earned (5 XP per correct answer)
        let xpPerCorrect = 5
        let totalXP = correctCount * xpPerCorrect
        
        // Award XP
        if let user = DatabaseManager.shared.fetchUser() {
            GamificationService.shared.awardXP(
                to: user.id,
                amount: totalXP,
                reason: "Mistake review",
                beliefSystemId: beliefSystem.id
            )
        }
        
        // Complete the session
        do {
            try DatabaseManager.shared.completeMistakeSession(
                sessionId: session.id,
                correctCount: correctCount,
                xpEarned: totalXP
            )
        } catch {
            AppLogger.logError(error, context: "Completing mistake session", logger: AppLogger.learning)
        }
        
        // Dismiss and notify delegate
        dismissReview { [weak self] in
            guard let self = self else { return }
            self.delegate?.mistakeReviewCompleted(
                correctCount: self.correctCount,
                totalCount: self.questions.count,
                xpEarned: totalXP
            )
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        PapyrusAlert(title: "Exit Review?", message: "Your progress will not be saved if you exit now.")
            .addAction(PapyrusAlert.Action(title: "Continue Review", style: .cancel))
            .addAction(PapyrusAlert.Action(title: "Exit", style: .destructive) { [weak self] in
                self?.exitReview()
            })
            .present(from: self)
    }
    
    private func exitReview() {
        // Add a small delay to ensure the alert is fully dismissed first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            // Dismiss and notify delegate
            self?.dismissReview { [weak self] in
                self?.delegate?.mistakeReviewCancelled()
            }
        }
    }
    
    private func dismissReview(completion: (() -> Void)? = nil) {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.dismissReview(completion: completion)
            }
            return
        }
        
        // Since we're presented inside a navigation controller, dismiss via the presenter
        if let navController = self.navigationController,
           let presenter = navController.presentingViewController {
            presenter.dismiss(animated: true, completion: completion)
        } else {
            // Fallback: dismiss directly
            self.dismiss(animated: true, completion: completion)
        }
    }
}

// MARK: - QuestionViewModelDelegate

extension MistakeReviewViewController: QuestionViewModelDelegate {
    func questionViewModel(_ viewModel: BaseQuestionViewModel, didAnswerCorrectly: Bool) {
        guard currentQuestionIndex < questions.count else { return }
        let question = questions[currentQuestionIndex]
        guard let mistake = questionToMistakeMap[question.id] else {
            AppLogger.logError(
                NSError(domain: "MistakeReview", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mistake found for answered question"]),
                context: "questionViewModel:didAnswerCorrectly:",
                logger: AppLogger.learning
            )
            return
        }
        
        if didAnswerCorrectly {
            correctCount += 1
            
            // Update mistake review status
            do {
                try DatabaseManager.shared.updateMistakeReview(
                    mistakeId: mistake.id,
                    wasCorrect: true
                )
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                AppLogger.logError(error, context: "Updating mistake review", logger: AppLogger.learning)
            }
        } else {
            // Reset mistake progress
            do {
                try DatabaseManager.shared.updateMistakeReview(
                    mistakeId: mistake.id,
                    wasCorrect: false
                )
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            } catch {
                AppLogger.logError(error, context: "Updating mistake review", logger: AppLogger.learning)
            }
        }
        
        currentQuestionIndex += 1
        
        // Delay before showing next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showNextQuestion()
        }
    }
    
    func questionViewModelDidRequestExit(_ viewModel: BaseQuestionViewModel) {
        cancelTapped()
    }
}