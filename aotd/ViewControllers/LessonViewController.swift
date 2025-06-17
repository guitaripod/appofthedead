import UIKit

final class LessonViewController: UIViewController {
    
    private let viewModel: LessonViewModel
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let lessonTitleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let contentTextView = UITextView()
    private let keyTermsStackView = UIStackView()
    private let continueButton = UIButton(type: .system)
    
    init(viewModel: LessonViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        configureWithViewModel()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .label
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.Papyrus.background
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.alignment = .fill
        scrollView.addSubview(contentStackView)
        
        setupProgressView()
        setupTitleLabel()
        setupContentTextView()
        setupKeyTermsSection()
        setupContinueButton()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func setupTitleLabel() {
        if let papyrusFont = UIFont(name: "Papyrus", size: 30) {
            lessonTitleLabel.font = papyrusFont
        } else {
            lessonTitleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        }
        lessonTitleLabel.textColor = UIColor.Papyrus.ink
        lessonTitleLabel.textAlignment = .left
        lessonTitleLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(lessonTitleLabel)
    }
    
    private func setupContentTextView() {
        contentTextView.isEditable = false
        contentTextView.isScrollEnabled = false
        contentTextView.font = .systemFont(ofSize: 17)
        contentTextView.textColor = UIColor.Papyrus.ink
        contentTextView.backgroundColor = .clear
        contentTextView.textContainerInset = .zero
        contentTextView.textContainer.lineFragmentPadding = 0
        contentStackView.addArrangedSubview(contentTextView)
    }
    
    private func setupKeyTermsSection() {
        let keyTermsLabel = UILabel()
        keyTermsLabel.text = "Key Terms"
        keyTermsLabel.font = .systemFont(ofSize: 20, weight: .bold)
        keyTermsLabel.textColor = UIColor.Papyrus.ink
        
        keyTermsStackView.axis = .vertical
        keyTermsStackView.spacing = 8
        keyTermsStackView.alignment = .fill
        
        let keyTermsContainer = UIStackView(arrangedSubviews: [keyTermsLabel, keyTermsStackView])
        keyTermsContainer.axis = .vertical
        keyTermsContainer.spacing = 12
        
        contentStackView.addArrangedSubview(keyTermsContainer)
    }
    
    private func setupContinueButton() {
        continueButton.setTitle("Continue to Quiz", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = UIColor.Papyrus.gold
        continueButton.setTitleColor(UIColor.Papyrus.ink, for: .normal)
        continueButton.layer.cornerRadius = 16
        continueButton.layer.shadowColor = UIColor.black.cgColor
        continueButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        continueButton.layer.shadowOpacity = 0.15
        continueButton.layer.shadowRadius = 4
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        contentStackView.addArrangedSubview(continueButton)
        
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func configureWithViewModel() {
        lessonTitleLabel.text = viewModel.lessonTitle
        contentTextView.text = viewModel.lessonContent
        progressView.progress = viewModel.progress
        progressView.trackTintColor = UIColor.Papyrus.aged.withAlphaComponent(0.3)
        
        if let beliefColor = viewModel.beliefSystemColor {
            progressView.progressTintColor = beliefColor
            // Keep gold for the continue button as it's more prominent
            continueButton.backgroundColor = UIColor.Papyrus.gold
        }
        
        keyTermsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for term in viewModel.keyTerms {
            let termView = createKeyTermView(term: term)
            keyTermsStackView.addArrangedSubview(termView)
        }
    }
    
    private func createKeyTermView(term: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.Papyrus.cardBackground
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.Papyrus.aged.cgColor
        
        let label = UILabel()
        label.text = term
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Papyrus.ink
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    @objc private func continueButtonTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.continueToQuiz()
    }
    
    @objc private func backButtonTapped() {
        print("DEBUG: LessonViewController - Back button tapped")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.exitLearningPath()
        print("DEBUG: LessonViewController - Called viewModel.exitLearningPath()")
    }
}