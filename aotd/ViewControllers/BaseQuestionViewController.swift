import UIKit

class BaseQuestionViewController: UIViewController {
    
    let viewModel: BaseQuestionViewModel
    
    let progressView = UIProgressView(progressViewStyle: .default)
    let questionNumberLabel = UILabel()
    let questionLabel = UILabel()
    let contentStackView = UIStackView()
    
    var submitButton: UIButton?
    var hideProgressView = false
    var hideQuestionNumber = false
    
    init(viewModel: BaseQuestionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupNavigationBar()
        configureWithViewModel()
    }
    
    private func setupNavigationBar() {
        // Make sure navigation bar is visible
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = true
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = UIColor.Papyrus.primaryText
        navigationItem.leftBarButtonItem = backButton
        
    }
    
    private func setupBaseUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.alignment = .fill
        view.addSubview(contentStackView)
        
        setupProgressView()
        setupQuestionNumberLabel()
        setupQuestionLabel()
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        // Hide if requested
        if hideProgressView {
            progressView.isHidden = true
        }
    }
    
    private func setupQuestionNumberLabel() {
        questionNumberLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        questionNumberLabel.textColor = UIColor.Papyrus.secondaryText
        contentStackView.addArrangedSubview(questionNumberLabel)
        
        // Hide if requested
        if hideQuestionNumber {
            questionNumberLabel.isHidden = true
        }
    }
    
    private func setupQuestionLabel() {
        if let papyrusFont = UIFont(name: "Papyrus", size: 22) {
            questionLabel.font = papyrusFont
        } else {
            questionLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        }
        questionLabel.textColor = UIColor.Papyrus.primaryText
        questionLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(questionLabel)
    }
    
    func setupSubmitButton() {
        let button = UIButton(type: .system)
        button.setTitle("Check Answer", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.Papyrus.aged
        button.setTitleColor(UIColor.Papyrus.beige, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.15
        button.layer.shadowRadius = 4
        button.isEnabled = false
        button.addTarget(self, action: #selector(submitAnswer), for: .touchUpInside)
        
        submitButton = button
        
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func configureWithViewModel() {
        questionNumberLabel.text = "Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.totalQuestions)"
        questionLabel.text = viewModel.questionText
        progressView.progress = viewModel.progress
        progressView.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        
        if let color = viewModel.beliefSystemColor {
            progressView.progressTintColor = color
        }
    }
    
    func enableSubmitButton(_ enabled: Bool) {
        submitButton?.isEnabled = enabled
        submitButton?.backgroundColor = enabled ? PapyrusDesignSystem.Colors.Component.Button.primaryBackground : PapyrusDesignSystem.Colors.Component.Button.disabledBackground
        submitButton?.setTitleColor(enabled ? PapyrusDesignSystem.Colors.Component.Button.primaryForeground : PapyrusDesignSystem.Colors.Component.Button.disabledForeground, for: .normal)
    }
    
    @objc func submitAnswer() {
        // To be overridden by subclasses
    }
    
    @objc private func backButtonTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.exitQuiz()
    }
    
    func showFeedback(isCorrect: Bool, explanation: String, completion: @escaping () -> Void) {
        UIImpactFeedbackGenerator(style: isCorrect ? .medium : .heavy).impactOccurred()
        
        let feedbackView = QuestionFeedbackView(
            isCorrect: isCorrect,
            explanation: explanation,
            xpReward: isCorrect ? viewModel.xpReward : 0
        )
        
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        feedbackView.alpha = 0
        feedbackView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        view.addSubview(feedbackView)
        
        NSLayoutConstraint.activate([
            feedbackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            feedbackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            feedbackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            feedbackView.alpha = 1
            feedbackView.transform = .identity
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                UIView.animate(withDuration: 0.3, animations: {
                    feedbackView.alpha = 0
                    feedbackView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }) { _ in
                    feedbackView.removeFromSuperview()
                    completion()
                }
            }
        }
    }
}