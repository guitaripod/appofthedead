import UIKit

protocol BookReaderSettingsDelegate: AnyObject {
    func settingsDidUpdateFontSize(_ size: Double)
    func settingsDidUpdateBrightness(_ brightness: Double)
    func settingsDidUpdateTTSSpeed(_ speed: Float)
    func settingsDidUpdateAutoScrollSpeed(_ speed: Double)
}

final class BookReaderSettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: BookReaderSettingsDelegate?
    private let preferences: BookReadingPreferences
    
    // MARK: - UI Components
    
    private lazy var fontSizeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 14
        slider.maximumValue = 28
        slider.value = Float(preferences.fontSize)
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(fontSizeChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var brightnessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.3
        slider.maximumValue = 1.0
        slider.value = Float(preferences.brightness)
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(brightnessChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var ttsSpeedSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 2.0
        slider.value = preferences.ttsSpeed
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(ttsSpeedChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var autoScrollSpeedSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 10
        slider.maximumValue = 100
        slider.value = Float(preferences.autoScrollSpeed ?? 50.0)
        slider.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        slider.addTarget(self, action: #selector(autoScrollSpeedChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    // MARK: - Initialization
    
    init(preferences: BookReadingPreferences) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        
        let fontSizeLabel = createSettingLabel("Font Size")
        let brightnessLabel = createSettingLabel("Brightness")
        let ttsSpeedLabel = createSettingLabel("TTS Speed")
        let autoScrollSpeedLabel = createSettingLabel("Auto-Scroll Speed")
        
        let fontStack = UIStackView(arrangedSubviews: [fontSizeLabel, fontSizeSlider])
        fontStack.axis = .vertical
        fontStack.spacing = 8
        
        let brightnessStack = UIStackView(arrangedSubviews: [brightnessLabel, brightnessSlider])
        brightnessStack.axis = .vertical
        brightnessStack.spacing = 8
        
        let ttsStack = UIStackView(arrangedSubviews: [ttsSpeedLabel, ttsSpeedSlider])
        ttsStack.axis = .vertical
        ttsStack.spacing = 8
        
        let autoScrollStack = UIStackView(arrangedSubviews: [autoScrollSpeedLabel, autoScrollSpeedSlider])
        autoScrollStack.axis = .vertical
        autoScrollStack.spacing = 8
        
        let mainStack = UIStackView(arrangedSubviews: [fontStack, brightnessStack, ttsStack, autoScrollStack])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createSettingLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = PapyrusDesignSystem.Typography.body()
        label.textColor = PapyrusDesignSystem.Colors.ancientInk
        return label
    }
    
    // MARK: - Actions
    
    @objc private func fontSizeChanged(_ slider: UISlider) {
        delegate?.settingsDidUpdateFontSize(Double(slider.value))
    }
    
    @objc private func brightnessChanged(_ slider: UISlider) {
        delegate?.settingsDidUpdateBrightness(Double(slider.value))
    }
    
    @objc private func ttsSpeedChanged(_ slider: UISlider) {
        delegate?.settingsDidUpdateTTSSpeed(slider.value)
    }
    
    @objc private func autoScrollSpeedChanged(_ slider: UISlider) {
        delegate?.settingsDidUpdateAutoScrollSpeed(Double(slider.value))
    }
}