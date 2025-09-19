import UIKit
import AVFoundation

protocol BookReaderSettingsDelegate: AnyObject {
    func settingsDidUpdateFontSize(_ size: Double)
    func settingsDidUpdateFontFamily(_ family: String)
    func settingsDidUpdateFontWeight(_ weight: String)
    func settingsDidUpdateLineSpacing(_ spacing: Double)
    func settingsDidUpdateParagraphSpacing(_ spacing: Double)
    func settingsDidUpdateFirstLineIndent(_ indent: Double)
    func settingsDidUpdateTextAlignment(_ alignment: String)
    func settingsDidUpdateMargins(_ size: Double)
    func settingsDidUpdateTheme(_ theme: String)
    func settingsDidUpdateBrightness(_ brightness: Double)
    func settingsDidUpdateTTSSpeed(_ speed: Float)
    func settingsDidUpdateAutoScrollSpeed(_ speed: Double)
    func settingsDidUpdateHyphenation(_ enabled: Bool)
    func settingsDidUpdatePageProgress(_ enabled: Bool)
    func settingsDidUpdateKeepScreenOn(_ enabled: Bool)
    func settingsDidUpdateSwipeGestures(_ enabled: Bool)
    func settingsDidUpdatePageTransition(_ style: String)
}

final class BookReaderSettingsViewController: UIViewController {
    
    
    
    enum Section: Int, CaseIterable {
        case appearance
        case textLayout
        case readingFeatures
        case automation
        
        var title: String {
            switch self {
            case .appearance: return "Appearance"
            case .textLayout: return "Text Layout"
            case .readingFeatures: return "Reading Features"
            case .automation: return "Automation"
            }
        }
    }
    
    enum Item: Hashable {
        case theme(value: String)
        case fontFamily(value: String)
        case fontSize(value: Double)
        case fontWeight(value: String)
        case brightness(value: Double)
        case textAlignment(value: String)
        case lineSpacing(value: Double)
        case paragraphSpacing(value: Double)
        case firstLineIndent(value: Double)
        case margins(value: Double)
        case hyphenation(enabled: Bool)
        case pageTransition(style: String)
        case pageProgress(enabled: Bool)
        case keepScreenOn(enabled: Bool)
        case swipeGestures(enabled: Bool)
        case autoScrollSpeed(value: Double)
        case ttsSpeed(value: Double)
        case ttsVoice(value: String)
    }
    
    
    
    weak var delegate: BookReaderSettingsDelegate?
    private var preferences: BookReadingPreferences
    private let databaseManager = DatabaseManager.shared
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        
        let titleLabel = UILabel()
        titleLabel.text = "Reading Settings"
        titleLabel.font = PapyrusDesignSystem.Typography.title3()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = PapyrusDesignSystem.Colors.ancientInk
        closeButton.addTarget(self, action: #selector(closeSettings), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return view
    }()
    
    
    
    init(preferences: BookReadingPreferences) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        applySnapshot()
    }
    
    
    
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] sectionIndex, _ in
            guard let self = self,
                  let section = Section(rawValue: sectionIndex) else { return nil }
            
            
            switch section {
            case .appearance:
                return self.createAppearanceSection()
            case .textLayout, .readingFeatures, .automation:
                return self.createStandardSection()
            }
        }, configuration: config)
        
        
        layout.register(
            SectionHeaderView.self,
            forDecorationViewOfKind: UICollectionView.elementKindSectionHeader
        )
        
        return layout
    }
    
    private func createAppearanceSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 12
        
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createStandardSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 8
        
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func configureDataSource() {
        
        collectionView.register(ThemeSettingCell.self, forCellWithReuseIdentifier: "ThemeCell")
        collectionView.register(FontFamilySettingCell.self, forCellWithReuseIdentifier: "FontFamilyCell")
        collectionView.register(SliderSettingCell.self, forCellWithReuseIdentifier: "SliderCell")
        collectionView.register(SegmentedSettingCell.self, forCellWithReuseIdentifier: "SegmentedCell")
        collectionView.register(SwitchSettingCell.self, forCellWithReuseIdentifier: "SwitchCell")
        
        
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader"
        )
        
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return nil }
            
            switch item {
            case .theme(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThemeCell", for: indexPath) as! ThemeSettingCell
                cell.configure(value: value, delegate: self)
                return cell
                
            case .fontFamily(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontFamilyCell", for: indexPath) as! FontFamilySettingCell
                cell.configure(value: value, delegate: self)
                return cell
                
            case .fontSize(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "Font Size", value: value, min: 12, max: 32, format: { "\(Int($0))pt" }, delegate: self)
                return cell
                
            case .fontWeight(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: "Font Weight", value: value, options: ["Light", "Regular", "Medium", "Semibold", "Bold"], delegate: self)
                return cell
                
            case .brightness(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "Brightness", value: value, min: 0.3, max: 1.0, format: { "\(Int($0 * 100))%" }, delegate: self)
                return cell
                
            case .textAlignment(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: "Text Alignment", value: value, options: ["Left", "Center", "Right", "Justified"], delegate: self)
                return cell
                
            case .lineSpacing(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "Line Spacing", value: value, min: 1.0, max: 2.5, format: { String(format: "%.1f", $0) }, delegate: self)
                return cell
                
            case .paragraphSpacing(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "Paragraph Spacing", value: value, min: 1.0, max: 2.0, format: { String(format: "%.1f", $0) }, delegate: self)
                return cell
                
            case .firstLineIndent(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "First Line Indent", value: value, min: 0, max: 50, format: { "\(Int($0))" }, delegate: self)
                return cell
                
            case .margins(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "Margins", value: value, min: 10, max: 50, format: { "\(Int($0))" }, delegate: self)
                return cell
                
            case .hyphenation(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: "Enable Hyphenation", value: enabled, delegate: self)
                return cell
                
            case .pageTransition(let style):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: "Page Transition", value: style, options: ["Scroll", "Page Turn"], delegate: self)
                return cell
                
            case .pageProgress(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: "Show Page Progress", value: enabled, delegate: self)
                return cell
                
            case .keepScreenOn(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: "Keep Screen On", value: enabled, delegate: self)
                return cell
                
            case .swipeGestures(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: "Enable Swipe Gestures", value: enabled, delegate: self)
                return cell
                
            case .autoScrollSpeed(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "Auto-Scroll Speed", value: value, min: 10, max: 100, format: { "\(Int($0))" }, delegate: self)
                return cell
                
            case .ttsSpeed(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: "TTS Speed", value: value, min: 0.5, max: 2.0, format: { String(format: "%.1fx", $0) }, delegate: self)
                return cell
                
            case .ttsVoice(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: "TTS Voice", value: value, options: getAvailableVoices(), delegate: self)
                return cell
            }
        }
        
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "SectionHeader",
                for: indexPath
            ) as! SectionHeaderView
            
            let section = Section(rawValue: indexPath.section)!
            header.configure(title: section.title)
            
            return header
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        
        snapshot.appendSections([.appearance])
        snapshot.appendItems([
            .theme(value: preferences.theme),
            .fontFamily(value: preferences.fontFamily),
            .fontSize(value: preferences.fontSize),
            .fontWeight(value: preferences.fontWeight),
            .brightness(value: preferences.brightness)
        ], toSection: .appearance)
        
        
        snapshot.appendSections([.textLayout])
        snapshot.appendItems([
            .textAlignment(value: preferences.textAlignment),
            .lineSpacing(value: preferences.lineSpacing),
            .paragraphSpacing(value: preferences.paragraphSpacing),
            .firstLineIndent(value: preferences.firstLineIndent),
            .margins(value: preferences.marginSize),
            .hyphenation(enabled: preferences.enableHyphenation)
        ], toSection: .textLayout)
        
        
        snapshot.appendSections([.readingFeatures])
        snapshot.appendItems([
            .pageTransition(style: preferences.pageTransitionStyle),
            .pageProgress(enabled: preferences.showPageProgress),
            .keepScreenOn(enabled: preferences.keepScreenOn),
            .swipeGestures(enabled: preferences.enableSwipeGestures)
        ], toSection: .readingFeatures)
        
        
        snapshot.appendSections([.automation])
        snapshot.appendItems([
            .autoScrollSpeed(value: preferences.autoScrollSpeed ?? 50.0),
            .ttsSpeed(value: Double(preferences.ttsSpeed)),
            .ttsVoice(value: preferences.ttsVoice ?? "Default")
        ], toSection: .automation)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func getAvailableVoices() -> [String] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .prefix(5)
            .map { $0.name }
        return ["Default"] + voices
    }
    
    
    
    @objc private func closeSettings() {
        savePreferences()
        dismiss(animated: true)
    }
    
    private func savePreferences() {
        Task {
            do {
                try databaseManager.updateBookReadingPreferences(preferences)
            } catch {
                AppLogger.database.error("Failed to save reading preferences: \(error)")
            }
        }
    }
}



protocol SettingsCellDelegate: AnyObject {
    func settingValueChanged(_ value: Any, for indexPath: IndexPath)
}

extension BookReaderSettingsViewController: SettingsCellDelegate {
    func settingValueChanged(_ value: Any, for indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .theme:
            preferences.theme = value as? String ?? "papyrus"
            delegate?.settingsDidUpdateTheme(preferences.theme)
            
        case .fontFamily:
            preferences.fontFamily = value as? String ?? "Georgia"
            delegate?.settingsDidUpdateFontFamily(preferences.fontFamily)
            
        case .fontSize:
            preferences.fontSize = value as? Double ?? 18.0
            delegate?.settingsDidUpdateFontSize(preferences.fontSize)
            
        case .fontWeight:
            preferences.fontWeight = value as? String ?? "regular"
            delegate?.settingsDidUpdateFontWeight(preferences.fontWeight)
            
        case .brightness:
            preferences.brightness = value as? Double ?? 1.0
            delegate?.settingsDidUpdateBrightness(preferences.brightness)
            
        case .textAlignment:
            preferences.textAlignment = value as? String ?? "justified"
            delegate?.settingsDidUpdateTextAlignment(preferences.textAlignment)
            
        case .lineSpacing:
            preferences.lineSpacing = value as? Double ?? 1.5
            delegate?.settingsDidUpdateLineSpacing(preferences.lineSpacing)
            
        case .paragraphSpacing:
            preferences.paragraphSpacing = value as? Double ?? 1.2
            delegate?.settingsDidUpdateParagraphSpacing(preferences.paragraphSpacing)
            
        case .firstLineIndent:
            preferences.firstLineIndent = value as? Double ?? 30.0
            delegate?.settingsDidUpdateFirstLineIndent(preferences.firstLineIndent)
            
        case .margins:
            preferences.marginSize = value as? Double ?? 20.0
            delegate?.settingsDidUpdateMargins(preferences.marginSize)
            
        case .hyphenation:
            preferences.enableHyphenation = value as? Bool ?? true
            delegate?.settingsDidUpdateHyphenation(preferences.enableHyphenation)
            
        case .pageTransition:
            preferences.pageTransitionStyle = value as? String ?? "scroll"
            delegate?.settingsDidUpdatePageTransition(preferences.pageTransitionStyle)
            
        case .pageProgress:
            preferences.showPageProgress = value as? Bool ?? true
            delegate?.settingsDidUpdatePageProgress(preferences.showPageProgress)
            
        case .keepScreenOn:
            preferences.keepScreenOn = value as? Bool ?? true
            delegate?.settingsDidUpdateKeepScreenOn(preferences.keepScreenOn)
            
        case .swipeGestures:
            preferences.enableSwipeGestures = value as? Bool ?? true
            delegate?.settingsDidUpdateSwipeGestures(preferences.enableSwipeGestures)
            
        case .autoScrollSpeed:
            preferences.autoScrollSpeed = value as? Double
            delegate?.settingsDidUpdateAutoScrollSpeed(preferences.autoScrollSpeed ?? 50.0)
            
        case .ttsSpeed:
            preferences.ttsSpeed = value as? Double ?? 1.0
            delegate?.settingsDidUpdateTTSSpeed(Float(preferences.ttsSpeed))
            
        case .ttsVoice:
            preferences.ttsVoice = value as? String
        }
        
        
        applySnapshot()
    }
}



class SectionHeaderView: UICollectionReusableView {
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.font = PapyrusDesignSystem.Typography.body(weight: .bold)
        titleLabel.textColor = PapyrusDesignSystem.Colors.goldLeaf
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(title: String) {
        titleLabel.text = title.uppercased()
    }
}



class BaseSettingCell: UICollectionViewCell {
    weak var delegate: SettingsCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
    }
}



class ThemeSettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private var themeButtons: [UIButton] = []
    private let stackView = UIStackView()
    private var currentValue: String = ""
    
    override func setupUI() {
        titleLabel.text = "Theme"
        titleLabel.font = PapyrusDesignSystem.Typography.body()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [titleLabel, stackView])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        setupThemeButtons()
    }
    
    private func setupThemeButtons() {
        let sortedThemes = ReadingTheme.themes.sorted { $0.key < $1.key }
        
        for (key, theme) in sortedThemes {
            let button = createThemeButton(theme: theme, key: key)
            themeButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    private func createThemeButton(theme: ReadingTheme, key: String) -> UIButton {
        let button = UIButton()
        button.backgroundColor = theme.backgroundColor
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.tag = themeButtons.count
        
        let label = UILabel()
        label.text = "Aa"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = theme.textColor
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        button.addTarget(self, action: #selector(themeButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func themeButtonTapped(_ sender: UIButton) {
        themeButtons.forEach { button in
            button.layer.borderColor = UIColor.clear.cgColor
            button.isSelected = false
        }
        
        sender.layer.borderColor = PapyrusDesignSystem.Colors.goldLeaf.cgColor
        sender.isSelected = true
        
        let sortedThemeKeys = ReadingTheme.themes.keys.sorted()
        let themeKey = sortedThemeKeys[sender.tag]
        
        if let indexPath = (superview as? UICollectionView)?.indexPath(for: self) {
            delegate?.settingValueChanged(themeKey, for: indexPath)
        }
    }
    
    func configure(value: String, delegate: SettingsCellDelegate) {
        self.delegate = delegate
        self.currentValue = value
        
        let sortedThemeKeys = ReadingTheme.themes.keys.sorted()
        if let index = sortedThemeKeys.firstIndex(of: value) {
            themeButtons[index].layer.borderColor = PapyrusDesignSystem.Colors.goldLeaf.cgColor
            themeButtons[index].isSelected = true
        }
    }
}



class FontFamilySettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private var currentValue: String = ""
    
    private let fonts = [
        "Georgia", "Palatino", "Baskerville", "Times New Roman",
        "Helvetica Neue", "San Francisco", "Avenir", "Charter"
    ]
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 50)
        layout.minimumInteritemSpacing = 8
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        titleLabel.text = "Font Family"
        titleLabel.font = PapyrusDesignSystem.Typography.body()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FontCell.self, forCellWithReuseIdentifier: "FontCell")
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, collectionView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func configure(value: String, delegate: SettingsCellDelegate) {
        self.delegate = delegate
        self.currentValue = value
        collectionView.reloadData()
    }
}

extension FontFamilySettingCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fonts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontCell", for: indexPath) as! FontCell
        let fontName = fonts[indexPath.item]
        cell.configure(fontName: fontName, isSelected: fontName == currentValue)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let parentIndexPath = (superview as? UICollectionView)?.indexPath(for: self) {
            delegate?.settingValueChanged(fonts[indexPath.item], for: parentIndexPath)
        }
    }
}

class FontCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = PapyrusDesignSystem.Colors.beige
        layer.cornerRadius = 8
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(fontName: String, isSelected: Bool) {
        label.text = "Aa"
        label.font = UIFont(name: fontName, size: 16) ?? .systemFont(ofSize: 16)
        layer.borderColor = isSelected ? PapyrusDesignSystem.Colors.goldLeaf.cgColor : UIColor.clear.cgColor
    }
}



class SliderSettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private var formatValue: ((Double) -> String)?
    
    override func setupUI() {
        titleLabel.font = PapyrusDesignSystem.Typography.body()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        
        valueLabel.font = PapyrusDesignSystem.Typography.caption1()
        valueLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        valueLabel.textAlignment = .right
        
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        let topStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        topStack.spacing = 8
        
        let mainStack = UIStackView(arrangedSubviews: [topStack, slider])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, value: Double, min: Double, max: Double, format: @escaping (Double) -> String, delegate: SettingsCellDelegate) {
        self.delegate = delegate
        self.formatValue = format
        
        titleLabel.text = title
        slider.minimumValue = Float(min)
        slider.maximumValue = Float(max)
        slider.value = Float(value)
        updateValueLabel()
    }
    
    @objc private func sliderChanged() {
        updateValueLabel()
        if let indexPath = (superview as? UICollectionView)?.indexPath(for: self) {
            delegate?.settingValueChanged(Double(slider.value), for: indexPath)
        }
    }
    
    private func updateValueLabel() {
        if let format = formatValue {
            valueLabel.text = format(Double(slider.value))
        } else {
            valueLabel.text = "\(Int(slider.value))"
        }
    }
}



class SegmentedSettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl()
    private var currentTitle: String = ""
    
    override func setupUI() {
        titleLabel.font = PapyrusDesignSystem.Typography.body()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.backgroundColor = PapyrusDesignSystem.Colors.beige
        segmentedControl.selectedSegmentTintColor = PapyrusDesignSystem.Colors.goldLeaf
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, segmentedControl])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(title: String, value: String, options: [String], delegate: SettingsCellDelegate) {
        self.delegate = delegate
        self.currentTitle = title
        
        titleLabel.text = title
        
        segmentedControl.removeAllSegments()
        options.enumerated().forEach { index, option in
            segmentedControl.insertSegment(withTitle: option, at: index, animated: false)
        }
        
        if let index = mapValueToSegmentIndex(value: value, for: title) {
            segmentedControl.selectedSegmentIndex = index
        }
    }
    
    @objc private func segmentChanged() {
        let value = mapSegmentIndexToValue(index: segmentedControl.selectedSegmentIndex, for: currentTitle)
        if let indexPath = (superview as? UICollectionView)?.indexPath(for: self) {
            delegate?.settingValueChanged(value, for: indexPath)
        }
    }
    
    private func mapValueToSegmentIndex(value: String, for title: String) -> Int? {
        switch title {
        case "Text Alignment":
            return ["left", "center", "right", "justified"].firstIndex(of: value)
        case "Font Weight":
            return ["light", "regular", "medium", "semibold", "bold"].firstIndex(of: value)
        case "Page Transition":
            return ["scroll", "page"].firstIndex(of: value)
        default:
            return nil
        }
    }
    
    private func mapSegmentIndexToValue(index: Int, for title: String) -> String {
        switch title {
        case "Text Alignment":
            return ["left", "center", "right", "justified"][index]
        case "Font Weight":
            return ["light", "regular", "medium", "semibold", "bold"][index]
        case "Page Transition":
            return ["scroll", "page"][index]
        default:
            return ""
        }
    }
}



class SwitchSettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()
    
    override func setupUI() {
        titleLabel.font = PapyrusDesignSystem.Typography.body()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        
        switchControl.onTintColor = PapyrusDesignSystem.Colors.goldLeaf
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, switchControl])
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func configure(title: String, value: Bool, delegate: SettingsCellDelegate) {
        self.delegate = delegate
        titleLabel.text = title
        switchControl.isOn = value
    }
    
    @objc private func switchChanged() {
        if let indexPath = (superview as? UICollectionView)?.indexPath(for: self) {
            delegate?.settingValueChanged(switchControl.isOn, for: indexPath)
        }
    }
}