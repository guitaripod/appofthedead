import UIKit

/// One question inside a quiz session: the question in serif under its position, a hint, and the answers a subclass
/// adds to `answersStack`. The session owns the Check button and the feedback; a question only says when an answer
/// is ready and, when asked, checks it and marks its answers right or wrong.
class BaseQuestionViewController: UIViewController {

    let viewModel: BaseQuestionViewModel
    let answersStack = UIStackView()

    /// Called whenever an answer becomes ready to check, or stops being ready.
    var onReadinessChange: ((Bool) -> Void)?

    private(set) var isReadyToCheck = false
    private(set) var isChecked = false

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let eyebrowLabel = UILabel()
    private let questionLabel = UILabel()
    private let hintLabel = UILabel()
    private let foldClearance = UIView()
    private let foldClearanceHeight: NSLayoutConstraint

    var accent: UIColor {
        viewModel.beliefSystemColor ?? PapyrusDesignSystem.Colors.Core.goldLeaf
    }

    /// A short instruction under the question, such as "Choose one answer".
    var hintText: String? { nil }

    /// The view to bring into sight once the answer is checked, usually the right answer.
    var revealFocusView: UIView? { nil }

    init(viewModel: BaseQuestionViewModel) {
        self.viewModel = viewModel
        self.foldClearanceHeight = foldClearance.heightAnchor.constraint(equalToConstant: 0)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupScrollView()
        setupHeader()
        setupAnswersStack()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        keepAnswersBelowFold()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        scrollView.addSubview(contentStack)
        let preferredWidth = contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        preferredWidth.priority = .required - 1
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 600),
            contentStack.widthAnchor.constraint(lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            preferredWidth,
        ])
    }

    private func setupHeader() {
        eyebrowLabel.attributedText = NSAttributedString(string: viewModel.positionText.uppercased(with: .current), attributes: [
            .kern: 1.6,
            .font: PapyrusDesignSystem.Typography.sans(12, weight: .semibold, textStyle: .caption1),
            .foregroundColor: accent,
        ])
        eyebrowLabel.adjustsFontForContentSizeCategory = true
        eyebrowLabel.numberOfLines = 0
        questionLabel.attributedText = QuizText.styled(
            viewModel.questionText,
            font: PapyrusDesignSystem.Typography.serif(25, weight: .semibold, textStyle: .title2),
            color: PapyrusDesignSystem.Colors.Dynamic.primaryText
        )
        questionLabel.adjustsFontForContentSizeCategory = true
        questionLabel.numberOfLines = 0
        questionLabel.accessibilityTraits = .header
        hintLabel.text = hintText
        hintLabel.font = PapyrusDesignSystem.Typography.sans(15, weight: .regular, textStyle: .subheadline)
        hintLabel.adjustsFontForContentSizeCategory = true
        hintLabel.textColor = PapyrusDesignSystem.Colors.Dynamic.tertiaryText
        hintLabel.numberOfLines = 0
        hintLabel.isHidden = hintText == nil
        [eyebrowLabel, questionLabel, hintLabel].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(10, after: eyebrowLabel)
        contentStack.setCustomSpacing(8, after: questionLabel)
        foldClearance.translatesAutoresizingMaskIntoConstraints = false
        foldClearanceHeight.isActive = true
        foldClearance.isHidden = true
        contentStack.addArrangedSubview(foldClearance)
    }

    private func setupAnswersStack() {
        answersStack.axis = .vertical
        answersStack.spacing = 12
        contentStack.addArrangedSubview(answersStack)
        contentStack.setCustomSpacing(26, after: hintLabel)
        contentStack.setCustomSpacing(26, after: foldClearance)
    }

    /// Marks whether an answer is ready to check and tells the session.
    func setReadyToCheck(_ ready: Bool) {
        guard ready != isReadyToCheck else { return }
        isReadyToCheck = ready
        onReadinessChange?(ready)
    }

    /// Checks the chosen answer once, marks the answers, and returns what the check showed.
    func submit() -> QuestionOutcome? {
        guard isReadyToCheck, !isChecked, let outcome = checkSelectedAnswer() else { return nil }
        isChecked = true
        return outcome
    }

    /// Subclasses check their answer here, mark their answers and describe the result.
    func checkSelectedAnswer() -> QuestionOutcome? {
        nil
    }

    /// Picks an answer from a hardware key; returns whether the key meant something here.
    func handleKeyInput(_ input: String) -> Bool {
        false
    }

    /// Leaves room under the answers for the feedback panel and brings the right answer into sight.
    func setBottomObstruction(_ height: CGFloat, animated: Bool) {
        scrollView.contentInset.bottom = height
        scrollView.verticalScrollIndicatorInsets.bottom = height
        guard height > 0, let focus = revealFocusView else { return }
        view.layoutIfNeeded()
        let target = focus.convert(focus.bounds, to: scrollView).insetBy(dx: 0, dy: -16)
        guard let offset = offsetRevealing(target) else { return }
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: offset), animated: animated && !UIAccessibility.isReduceMotionEnabled)
    }

    /// The vertical offset that shows `target` above the bottom inset, or nil when it is already in sight.
    /// `scrollRectToVisible` would ignore the inset and leave the answer under the feedback panel.
    private func offsetRevealing(_ target: CGRect) -> CGFloat? {
        let insets = scrollView.adjustedContentInset
        let visibleTop = scrollView.contentOffset.y + insets.top
        let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height - insets.bottom
        guard target.maxY > visibleBottom || target.minY < visibleTop else { return nil }
        let lowest = -insets.top
        let highest = max(lowest, scrollView.contentSize.height - scrollView.bounds.height + insets.bottom)
        let showingBottom = target.maxY - (scrollView.bounds.height - insets.bottom)
        let showingTop = target.minY - insets.top
        let visibleHeight = scrollView.bounds.height - insets.top - insets.bottom
        let wanted = target.height > visibleHeight ? showingTop : showingBottom
        return min(max(wanted, lowest), highest)
    }

    #if DEBUG
    /// Screenshot rig: chooses the right answer, or a wrong one.
    func demoChooseAnswer(correctly: Bool) {}
    #endif

    /// With the device half open and the fold running across the screen, the question stays in the
    /// upper half and every answer control sits in the lower half, so no control crosses the fold.
    private func keepAnswersBelowFold() {
        let required = requiredFoldClearance()
        guard abs(required - foldClearanceHeight.constant) > 0.5 else { return }
        foldClearanceHeight.constant = required
        foldClearance.isHidden = required == 0
        view.setNeedsLayout()
    }

    private func requiredFoldClearance() -> CGFloat {
        guard let fold = FoldRegion.activeFrame(in: view), fold.width > fold.height else { return 0 }
        let questionBottom = hintLabel.convert(hintLabel.bounds, to: view).maxY
        let answersTop = questionBottom + contentStack.spacing * 2
        return max(0, fold.maxY - answersTop)
    }

    /// Lays answer cards out side by side, or one above the other when the text is very large.
    func makeAdaptiveRow(_ views: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: views)
        row.spacing = 12
        row.distribution = .fillEqually
        row.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: BaseQuestionViewController, _) in
            row.axis = controller.traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        }
        return row
    }
}
