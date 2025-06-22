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
    
    // MARK: - Properties
    
    weak var delegate: BookReaderSettingsDelegate?
    private var preferences: BookReadingPreferences
    private let databaseManager = DatabaseManager.shared
    private var sections: [SettingsSection] = []
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        return table
    }()
    
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
    
    // MARK: - Initialization
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSections()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Register custom cells
        tableView.register(SliderSettingCell.self, forCellReuseIdentifier: "SliderCell")
        tableView.register(SegmentedSettingCell.self, forCellReuseIdentifier: "SegmentedCell")
        tableView.register(SwitchSettingCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.register(ThemeSelectionCell.self, forCellReuseIdentifier: "ThemeCell")
        tableView.register(FontSelectionCell.self, forCellReuseIdentifier: "FontCell")
    }
    
    private func setupSections() {
        sections = [
            // Appearance Section
            SettingsSection(title: "Appearance", items: [
                SettingItem(title: "Theme", type: .theme, value: preferences.theme),
                SettingItem(title: "Font Family", type: .fontFamily, value: preferences.fontFamily),
                SettingItem(title: "Font Size", type: .slider, value: preferences.fontSize, min: 12, max: 32),
                SettingItem(title: "Font Weight", type: .segmented, value: preferences.fontWeight,
                           options: ["Light", "Regular", "Medium", "Semibold", "Bold"]),
                SettingItem(title: "Brightness", type: .slider, value: preferences.brightness, min: 0.3, max: 1.0)
            ]),
            
            // Text Layout Section
            SettingsSection(title: "Text Layout", items: [
                SettingItem(title: "Text Alignment", type: .segmented, value: preferences.textAlignment,
                           options: ["Left", "Center", "Right", "Justified"]),
                SettingItem(title: "Line Spacing", type: .slider, value: preferences.lineSpacing, min: 1.0, max: 2.5),
                SettingItem(title: "Paragraph Spacing", type: .slider, value: preferences.paragraphSpacing, min: 1.0, max: 2.0),
                SettingItem(title: "First Line Indent", type: .slider, value: preferences.firstLineIndent, min: 0, max: 50),
                SettingItem(title: "Margins", type: .slider, value: preferences.marginSize, min: 10, max: 50),
                SettingItem(title: "Enable Hyphenation", type: .switch, value: preferences.enableHyphenation)
            ]),
            
            // Reading Features Section
            SettingsSection(title: "Reading Features", items: [
                SettingItem(title: "Page Transition", type: .segmented, value: preferences.pageTransitionStyle,
                           options: ["Scroll", "Page Turn"]),
                SettingItem(title: "Show Page Progress", type: .switch, value: preferences.showPageProgress),
                SettingItem(title: "Keep Screen On", type: .switch, value: preferences.keepScreenOn),
                SettingItem(title: "Enable Swipe Gestures", type: .switch, value: preferences.enableSwipeGestures)
            ]),
            
            // Automation Section
            SettingsSection(title: "Automation", items: [
                SettingItem(title: "Auto-Scroll Speed", type: .slider, value: preferences.autoScrollSpeed ?? 50.0, min: 10, max: 100),
                SettingItem(title: "TTS Speed", type: .slider, value: Double(preferences.ttsSpeed), min: 0.5, max: 2.0),
                SettingItem(title: "TTS Voice", type: .segmented, value: preferences.ttsVoice ?? "Default",
                           options: getAvailableVoices())
            ])
        ]
    }
    
    private func getAvailableVoices() -> [String] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .prefix(5)
            .map { $0.name }
        return ["Default"] + voices
    }
    
    // MARK: - Actions
    
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
    
    // MARK: - Helper Methods
    
    private func updatePreference(for item: SettingItem, value: Any) {
        switch item.title {
        case "Theme":
            preferences.theme = value as? String ?? "papyrus"
            delegate?.settingsDidUpdateTheme(preferences.theme)
        case "Font Family":
            preferences.fontFamily = value as? String ?? "Georgia"
            delegate?.settingsDidUpdateFontFamily(preferences.fontFamily)
        case "Font Size":
            preferences.fontSize = value as? Double ?? 18.0
            delegate?.settingsDidUpdateFontSize(preferences.fontSize)
        case "Font Weight":
            preferences.fontWeight = value as? String ?? "regular"
            delegate?.settingsDidUpdateFontWeight(preferences.fontWeight)
        case "Brightness":
            preferences.brightness = value as? Double ?? 1.0
            delegate?.settingsDidUpdateBrightness(preferences.brightness)
        case "Text Alignment":
            preferences.textAlignment = value as? String ?? "justified"
            delegate?.settingsDidUpdateTextAlignment(preferences.textAlignment)
        case "Line Spacing":
            preferences.lineSpacing = value as? Double ?? 1.5
            delegate?.settingsDidUpdateLineSpacing(preferences.lineSpacing)
        case "Paragraph Spacing":
            preferences.paragraphSpacing = value as? Double ?? 1.2
            delegate?.settingsDidUpdateParagraphSpacing(preferences.paragraphSpacing)
        case "First Line Indent":
            preferences.firstLineIndent = value as? Double ?? 30.0
            delegate?.settingsDidUpdateFirstLineIndent(preferences.firstLineIndent)
        case "Margins":
            preferences.marginSize = value as? Double ?? 20.0
            delegate?.settingsDidUpdateMargins(preferences.marginSize)
        case "Enable Hyphenation":
            preferences.enableHyphenation = value as? Bool ?? true
            delegate?.settingsDidUpdateHyphenation(preferences.enableHyphenation)
        case "Page Transition":
            preferences.pageTransitionStyle = value as? String ?? "scroll"
            delegate?.settingsDidUpdatePageTransition(preferences.pageTransitionStyle)
        case "Show Page Progress":
            preferences.showPageProgress = value as? Bool ?? true
            delegate?.settingsDidUpdatePageProgress(preferences.showPageProgress)
        case "Keep Screen On":
            preferences.keepScreenOn = value as? Bool ?? true
            delegate?.settingsDidUpdateKeepScreenOn(preferences.keepScreenOn)
        case "Enable Swipe Gestures":
            preferences.enableSwipeGestures = value as? Bool ?? true
            delegate?.settingsDidUpdateSwipeGestures(preferences.enableSwipeGestures)
        case "Auto-Scroll Speed":
            preferences.autoScrollSpeed = value as? Double
            delegate?.settingsDidUpdateAutoScrollSpeed(preferences.autoScrollSpeed ?? 50.0)
        case "TTS Speed":
            preferences.ttsSpeed = Float(value as? Double ?? 1.0)
            delegate?.settingsDidUpdateTTSSpeed(preferences.ttsSpeed)
        case "TTS Voice":
            preferences.ttsVoice = value as? String
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource

extension BookReaderSettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .slider:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as! SliderSettingCell
            cell.configure(with: item, delegate: self)
            return cell
            
        case .segmented:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedCell", for: indexPath) as! SegmentedSettingCell
            cell.configure(with: item, delegate: self)
            return cell
            
        case .switch:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchSettingCell
            cell.configure(with: item, delegate: self)
            return cell
            
        case .theme:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeCell", for: indexPath) as! ThemeSelectionCell
            cell.configure(with: item, delegate: self)
            return cell
            
        case .fontFamily:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FontCell", for: indexPath) as! FontSelectionCell
            cell.configure(with: item, delegate: self)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

// MARK: - UITableViewDelegate

extension BookReaderSettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item.type {
        case .theme:
            return 80
        case .fontFamily:
            return 120
        case .segmented:
            // Check if it's the font weight cell specifically
            if item.title == "Font Weight" {
                return 80  // Give more height for better visibility
            }
            return 80  // Standard height for segmented controls
        case .slider:
            return 80  // More height for sliders to prevent text cutoff
        case .switch:
            return 60  // Standard height for switches
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.text = sections[section].title
        label.font = PapyrusDesignSystem.Typography.body(weight: .bold)
        label.textColor = PapyrusDesignSystem.Colors.goldLeaf
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

// MARK: - SettingsCellDelegate

extension BookReaderSettingsViewController: SettingsCellDelegate {
    func settingValueChanged(_ item: SettingItem, value: Any) {
        updatePreference(for: item, value: value)
    }
}

// MARK: - Data Models

struct SettingsSection {
    let title: String
    let items: [SettingItem]
}

struct SettingItem {
    let title: String
    let type: SettingType
    var value: Any
    var min: Double?
    var max: Double?
    var options: [String]?
}

enum SettingType {
    case slider
    case segmented
    case `switch`
    case theme
    case fontFamily
}

// MARK: - Custom Cells

protocol SettingsCellDelegate: AnyObject {
    func settingValueChanged(_ item: SettingItem, value: Any)
}

// Base class for setting cells
class BaseSettingCell: UITableViewCell {
    weak var delegate: SettingsCellDelegate?
    var item: SettingItem?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        // Override in subclasses
    }
    
    func configure(with item: SettingItem, delegate: SettingsCellDelegate) {
        self.item = item
        self.delegate = delegate
    }
}

// Slider cell
class SliderSettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    
    override func setupUI() {
        titleLabel.font = PapyrusDesignSystem.Typography.body()
        titleLabel.textColor = PapyrusDesignSystem.Colors.ancientInk
        
        valueLabel.font = PapyrusDesignSystem.Typography.caption1()
        valueLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
        valueLabel.textAlignment = .right
        
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.spacing = 8
        
        let mainStack = UIStackView(arrangedSubviews: [stack, slider])
        mainStack.axis = .vertical
        mainStack.spacing = 12  // Increased spacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    override func configure(with item: SettingItem, delegate: SettingsCellDelegate) {
        super.configure(with: item, delegate: delegate)
        
        titleLabel.text = item.title
        slider.minimumValue = Float(item.min ?? 0)
        slider.maximumValue = Float(item.max ?? 100)
        slider.value = Float(item.value as? Double ?? 0)
        updateValueLabel()
    }
    
    @objc private func sliderChanged() {
        updateValueLabel()
        delegate?.settingValueChanged(item!, value: Double(slider.value))
    }
    
    private func updateValueLabel() {
        if item?.title == "Font Size" {
            valueLabel.text = "\(Int(slider.value))pt"
        } else if item?.title == "TTS Speed" {
            valueLabel.text = String(format: "%.1fx", slider.value)
        } else if item?.title == "Brightness" {
            valueLabel.text = "\(Int(slider.value * 100))%"
        } else {
            valueLabel.text = "\(Int(slider.value))"
        }
    }
}

// Segmented control cell
class SegmentedSettingCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl()
    
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
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    override func configure(with item: SettingItem, delegate: SettingsCellDelegate) {
        super.configure(with: item, delegate: delegate)
        
        titleLabel.text = item.title
        
        segmentedControl.removeAllSegments()
        item.options?.enumerated().forEach { index, option in
            segmentedControl.insertSegment(withTitle: option, at: index, animated: false)
        }
        
        // Map value to segment index
        if let currentValue = item.value as? String,
           let index = mapValueToSegmentIndex(value: currentValue, for: item.title) {
            segmentedControl.selectedSegmentIndex = index
        }
    }
    
    @objc private func segmentChanged() {
        let value = mapSegmentIndexToValue(index: segmentedControl.selectedSegmentIndex, for: item?.title ?? "")
        delegate?.settingValueChanged(item!, value: value)
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
            return item?.options?.firstIndex(of: value)
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
            return item?.options?[index] ?? ""
        }
    }
}

// Switch cell
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
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    override func configure(with item: SettingItem, delegate: SettingsCellDelegate) {
        super.configure(with: item, delegate: delegate)
        
        titleLabel.text = item.title
        switchControl.isOn = item.value as? Bool ?? false
    }
    
    @objc private func switchChanged() {
        delegate?.settingValueChanged(item!, value: switchControl.isOn)
    }
}

// Theme selection cell
class ThemeSelectionCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private var themeButtons: [UIButton] = []
    private let stackView = UIStackView()
    
    override func setupUI() {
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
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    override func configure(with item: SettingItem, delegate: SettingsCellDelegate) {
        super.configure(with: item, delegate: delegate)
        
        titleLabel.text = item.title
        
        // Clear existing buttons
        themeButtons.forEach { $0.removeFromSuperview() }
        themeButtons.removeAll()
        
        // Sort themes to ensure consistent order
        let sortedThemes = ReadingTheme.themes.sorted { $0.key < $1.key }
        
        // Create theme buttons
        for (key, theme) in sortedThemes {
            let button = createThemeButton(theme: theme, key: key)
            button.isSelected = (item.value as? String) == key
            if button.isSelected {
                button.layer.borderColor = PapyrusDesignSystem.Colors.goldLeaf.cgColor
            }
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
        // Update selection state
        themeButtons.forEach { button in
            button.layer.borderColor = UIColor.clear.cgColor
            button.isSelected = false
        }
        
        sender.layer.borderColor = PapyrusDesignSystem.Colors.goldLeaf.cgColor
        sender.isSelected = true
        
        // Get theme key - use sorted order
        let sortedThemeKeys = ReadingTheme.themes.keys.sorted()
        let themeKey = sortedThemeKeys[sender.tag]
        
        delegate?.settingValueChanged(item!, value: themeKey)
    }
}

// Font selection cell
class FontSelectionCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    
    private let fonts = [
        "Georgia", "Palatino", "Baskerville", "Times New Roman",
        "Helvetica Neue", "San Francisco", "Avenir", "Charter"
    ]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 60)
        layout.minimumInteritemSpacing = 8
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
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
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    override func configure(with item: SettingItem, delegate: SettingsCellDelegate) {
        super.configure(with: item, delegate: delegate)
        titleLabel.text = item.title
        collectionView.reloadData()
    }
}

extension FontSelectionCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fonts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontCell", for: indexPath) as! FontCell
        let fontName = fonts[indexPath.item]
        cell.configure(fontName: fontName, isSelected: fontName == (item?.value as? String))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.settingValueChanged(item!, value: fonts[indexPath.item])
        collectionView.reloadData()
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
        label.font = UIFont(name: fontName, size: 18) ?? .systemFont(ofSize: 18)
        layer.borderColor = isSelected ? PapyrusDesignSystem.Colors.goldLeaf.cgColor : UIColor.clear.cgColor
    }
}