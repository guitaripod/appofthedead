import UIKit
import AVFoundation
extension BookReaderViewController {
    func updateLayoutForIPad() {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        if AdaptiveLayoutManager.shared.isRegularWidth(traitCollection) && 
           traitCollection.verticalSizeClass == .regular {
            setupTwoPageLayout()
        } else {
            setupSinglePageLayout()
        }
    }
    private func setupTwoPageLayout() {
        updateTextViewForIPad()
        updateToolbarsForIPad()
        addPageNavigationGestures()
    }
    private func setupSinglePageLayout() {
        updateTextViewForStandard()
    }
    private func updateTextViewForIPad() {
        let layoutManager = AdaptiveLayoutManager.shared
        let insets = layoutManager.contentInsets(for: traitCollection)
        textView.textContainerInset = UIEdgeInsets(
            top: 140,
            left: insets.left * 2,
            bottom: 120,
            right: insets.right * 2
        )
        updateTextAttributesForIPad()
    }
    private func updateTextViewForStandard() {
        textView.textContainerInset = UIEdgeInsets(
            top: 120,
            left: 20,
            bottom: 100,
            right: 20
        )
    }
    private func updateToolbarsForIPad() {
        addIPadToolbarControls()
    }
    private func addIPadToolbarControls() {
        let tocButton = UIButton(type: .system)
        tocButton.setImage(UIImage(systemName: "list.bullet.rectangle"), for: .normal)
        tocButton.tintColor = PapyrusDesignSystem.Colors.ancientInk
        tocButton.addTarget(self, action: #selector(showTableOfContents), for: .touchUpInside)
        bottomToolbar.addSubview(tocButton)
        let searchButton = UIButton(type: .system)
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = PapyrusDesignSystem.Colors.ancientInk
        searchButton.addTarget(self, action: #selector(showSearch), for: .touchUpInside)
        bottomToolbar.addSubview(searchButton)
        tocButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tocButton.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 60),
            tocButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -60),
            searchButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor)
        ])
    }
    private func addPageNavigationGestures() {
        let leftEdgeGesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleLeftEdgeSwipe(_:))
        )
        leftEdgeGesture.edges = .left
        view.addGestureRecognizer(leftEdgeGesture)
        let rightEdgeGesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleRightEdgeSwipe(_:))
        )
        rightEdgeGesture.edges = .right
        view.addGestureRecognizer(rightEdgeGesture)
        let twoFingerTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTwoFingerTap(_:))
        )
        twoFingerTap.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerTap)
    }
    private func updateTextAttributesForIPad() {
        guard let attributedText = textView.attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let range = NSRange(location: 0, length: mutableText.length)
        let preferences = viewModel.preferences
        let layoutManager = AdaptiveLayoutManager.shared
        let baseFontSize = CGFloat(preferences.fontSize)
        let multiplier = layoutManager.fontSizeMultiplier(for: traitCollection)
        let adjustedFontSize = baseFontSize * multiplier
        mutableText.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
            if let font = value as? UIFont {
                let newFont = UIFont(name: font.fontName, size: adjustedFontSize) ?? 
                             UIFont.systemFont(ofSize: adjustedFontSize)
                mutableText.addAttribute(.font, value: newFont, range: range)
            }
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(preferences.lineSpacing) * multiplier
        paragraphStyle.alignment = .justified
        mutableText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        textView.attributedText = mutableText
    }
    @objc private func showTableOfContents() {
        let tocVC = BookTableOfContentsViewController(viewModel: viewModel)
        tocVC.delegate = self
        let navController = UINavigationController(rootViewController: tocVC)
        navController.modalPresentationStyle = .pageSheet
        navController.preferredContentSize = CGSize(width: 400, height: 600)
        if let popover = navController.popoverPresentationController {
            popover.sourceView = bottomToolbar
            popover.sourceRect = CGRect(x: 60, y: bottomToolbar.bounds.height/2, width: 0, height: 0)
            popover.permittedArrowDirections = [.down]
        }
        present(navController, animated: true)
    }
    @objc private func showSearch() {
        let searchVC = BookSearchViewController(viewModel: viewModel)
        searchVC.delegate = self
        let navController = UINavigationController(rootViewController: searchVC)
        navController.modalPresentationStyle = .pageSheet
        navController.preferredContentSize = CGSize(width: 400, height: 500)
        if let popover = navController.popoverPresentationController {
            popover.sourceView = bottomToolbar
            popover.sourceRect = CGRect(x: bottomToolbar.bounds.width - 60, y: bottomToolbar.bounds.height/2, width: 0, height: 0)
            popover.permittedArrowDirections = [.down]
        }
        present(navController, animated: true)
    }
    @objc private func handleLeftEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            previousChapterTapped()
        }
    }
    @objc private func handleRightEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            nextChapterTapped()
        }
    }
    @objc private func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
        toggleControls()
    }
    private func toggleControls() {
        let alpha: CGFloat = controlsHidden ? 1.0 : 0.0
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.headerView.alpha = alpha
            self?.bottomToolbar.alpha = alpha
        }
        controlsHidden.toggle()
    }
}
protocol BookTableOfContentsDelegate: AnyObject {
    func didSelectChapter(at index: Int)
}
final class BookTableOfContentsViewController: UIViewController {
    weak var delegate: BookTableOfContentsDelegate?
    private let viewModel: BookReaderViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    init(viewModel: BookReaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    private func setupUI() {
        title = "Table of Contents"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissTapped)
        )
        view.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.background
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChapterCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}
extension BookTableOfContentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.chapterCount
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterCell", for: indexPath)
        cell.textLabel?.text = "Chapter \(indexPath.row + 1)"
        cell.textLabel?.font = PapyrusDesignSystem.Typography.body(for: traitCollection)
        cell.textLabel?.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        if indexPath.row == viewModel.currentChapterIndex {
            cell.accessoryType = .checkmark
            cell.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        } else {
            cell.accessoryType = .none
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .default
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectChapter(at: indexPath.row)
        dismiss(animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}
protocol BookSearchDelegate: AnyObject {
    func didSelectSearchResult(at position: Int)
}
final class BookSearchViewController: UIViewController {
    weak var delegate: BookSearchDelegate?
    private let viewModel: BookReaderViewModel
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var searchResults: [(chapter: Int, snippet: String, position: Int)] = []
    init(viewModel: BookReaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    private func setupUI() {
        title = "Search Book"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissTapped)
        )
        view.backgroundColor = PapyrusDesignSystem.Colors.Dynamic.background
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search for text..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.becomeFirstResponder()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        view.addSubview(searchBar)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    private func performSearch(query: String) {
        searchResults = []
        if let currentText = viewModel.currentChapterText,
           let range = currentText.lowercased().range(of: query.lowercased()) {
            let startIndex = currentText.distance(from: currentText.startIndex, to: range.lowerBound)
            let snippetStart = max(0, startIndex - 50)
            let snippetEnd = min(currentText.count, startIndex + query.count + 50)
            let snippet = String(currentText[currentText.index(currentText.startIndex, offsetBy: snippetStart)..<currentText.index(currentText.startIndex, offsetBy: snippetEnd)])
            searchResults.append((
                chapter: viewModel.currentChapterIndex,
                snippet: "..." + snippet + "...",
                position: startIndex
            ))
        }
        tableView.reloadData()
    }
}
extension BookSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count >= 3 {
            performSearch(query: searchText)
        } else {
            searchResults = []
            tableView.reloadData()
        }
    }
}
extension BookSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.snippet
        cell.textLabel?.font = PapyrusDesignSystem.Typography.footnote(for: traitCollection)
        cell.textLabel?.textColor = PapyrusDesignSystem.Colors.Dynamic.primaryText
        cell.textLabel?.numberOfLines = 3
        cell.detailTextLabel?.text = "Chapter \(result.chapter + 1)"
        cell.detailTextLabel?.font = PapyrusDesignSystem.Typography.caption1(for: traitCollection)
        cell.detailTextLabel?.textColor = PapyrusDesignSystem.Colors.Dynamic.secondaryText
        cell.backgroundColor = .clear
        cell.selectionStyle = .default
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = searchResults[indexPath.row]
        viewModel.currentChapterIndex = result.chapter
        delegate?.didSelectSearchResult(at: result.position)
        dismiss(animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
}
extension BookReaderViewController: BookTableOfContentsDelegate {
    func didSelectChapter(at index: Int) {
        viewModel.currentChapterIndex = index
        viewModel.loadCurrentChapter()
    }
}
extension BookReaderViewController: BookSearchDelegate {
    func didSelectSearchResult(at position: Int) {
        if let text = textView.text, position < text.count {
            let range = NSRange(location: position, length: 1)
            textView.scrollRangeToVisible(range)
            highlightSearchResult(at: range)
        }
    }
    private func highlightSearchResult(at range: NSRange) {
        let highlight = UIView()
        highlight.backgroundColor = PapyrusDesignSystem.Colors.goldLeaf.withAlphaComponent(0.3)
        highlight.layer.cornerRadius = 2
            if let textPosition = textView.position(from: textView.beginningOfDocument, offset: range.location),
               let endPosition = textView.position(from: textPosition, offset: range.length) {
            let textRange = textView.textRange(from: textPosition, to: endPosition)!
            let glyphRect = textView.firstRect(for: textRange)
            highlight.frame = glyphRect
            textView.addSubview(highlight)
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut) {
                highlight.alpha = 0
            } completion: { _ in
                highlight.removeFromSuperview()
            }
        }
    }
}