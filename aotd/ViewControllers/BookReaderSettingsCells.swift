import UIKit

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
        titleLabel.text = String(localized: "Theme")
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
        titleLabel.text = String(localized: "Font Family")
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
    
    static let textAlignmentTitle = String(localized: "Text Alignment")
    static let fontWeightTitle = String(localized: "Font Weight")
    static let pageTransitionTitle = String(localized: "Page Transition")
    
    private func mapValueToSegmentIndex(value: String, for title: String) -> Int? {
        switch title {
        case Self.textAlignmentTitle:
            return ["left", "center", "right", "justified"].firstIndex(of: value)
        case Self.fontWeightTitle:
            return ["light", "regular", "medium", "semibold", "bold"].firstIndex(of: value)
        case Self.pageTransitionTitle:
            return ["scroll", "page"].firstIndex(of: value)
        default:
            return nil
        }
    }
    
    private func mapSegmentIndexToValue(index: Int, for title: String) -> String {
        switch title {
        case Self.textAlignmentTitle:
            return ["left", "center", "right", "justified"][index]
        case Self.fontWeightTitle:
            return ["light", "regular", "medium", "semibold", "bold"][index]
        case Self.pageTransitionTitle:
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
