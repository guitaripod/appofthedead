import UIKit
import AVFoundation
import MidgarCore

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
            case .appearance: return String(localized: "Appearance")
            case .textLayout: return String(localized: "Text Layout")
            case .readingFeatures: return String(localized: "Reading Features")
            case .automation: return String(localized: "Automation")
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
        titleLabel.text = String(localized: "Reading Settings")
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
            
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
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
            headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
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
                cell.configure(title: String(localized: "Font Size"), value: value, min: 12, max: 32, format: { "\(Int($0))pt" }, delegate: self)
                return cell
                
            case .fontWeight(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: SegmentedSettingCell.fontWeightTitle, value: value, options: [String(localized: "Light"), String(localized: "Regular"), String(localized: "Medium"), String(localized: "Semibold"), String(localized: "Bold")], delegate: self)
                return cell
                
            case .brightness(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "Brightness"), value: value, min: 0.3, max: 1.0, format: { "\(Int($0 * 100))%" }, delegate: self)
                return cell
                
            case .textAlignment(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: SegmentedSettingCell.textAlignmentTitle, value: value, options: [String(localized: "Left"), String(localized: "Center"), String(localized: "Right"), String(localized: "Justified")], delegate: self)
                return cell
                
            case .lineSpacing(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "Line Spacing"), value: value, min: 1.0, max: 2.5, format: { String(format: "%.1f", $0) }, delegate: self)
                return cell
                
            case .paragraphSpacing(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "Paragraph Spacing"), value: value, min: 1.0, max: 2.0, format: { String(format: "%.1f", $0) }, delegate: self)
                return cell
                
            case .firstLineIndent(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "First Line Indent"), value: value, min: 0, max: 50, format: { "\(Int($0))" }, delegate: self)
                return cell
                
            case .margins(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "Margins"), value: value, min: 10, max: 50, format: { "\(Int($0))" }, delegate: self)
                return cell
                
            case .hyphenation(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: String(localized: "Enable Hyphenation"), value: enabled, delegate: self)
                return cell
                
            case .pageTransition(let style):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: SegmentedSettingCell.pageTransitionTitle, value: style, options: [String(localized: "Scroll"), String(localized: "Page Turn")], delegate: self)
                return cell
                
            case .pageProgress(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: String(localized: "Show Page Progress"), value: enabled, delegate: self)
                return cell
                
            case .keepScreenOn(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: String(localized: "Keep Screen On"), value: enabled, delegate: self)
                return cell
                
            case .swipeGestures(let enabled):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
                cell.configure(title: String(localized: "Enable Swipe Gestures"), value: enabled, delegate: self)
                return cell
                
            case .autoScrollSpeed(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "Auto-Scroll Speed"), value: value, min: 10, max: 100, format: { "\(Int($0))" }, delegate: self)
                return cell
                
            case .ttsSpeed(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
                cell.configure(title: String(localized: "TTS Speed"), value: value, min: 0.5, max: 2.0, format: { String(format: "%.1fx", $0) }, delegate: self)
                return cell
                
            case .ttsVoice(let value):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
                cell.configure(title: String(localized: "TTS Voice"), value: value, options: getAvailableVoices(), delegate: self)
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
                MidgarLog.error("Failed to save reading preferences: \(error)", category: .database)
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
