import UIKit

final class BookListCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.beige
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private lazy var bookSpineView: UIView = {
        let view = UIView()
        view.backgroundColor = PapyrusDesignSystem.Colors.ancientInk.withAlphaComponent(0.8)
        view.layer.cornerRadius = 2
        return view
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = PapyrusDesignSystem.Colors.goldLeaf.withAlphaComponent(0.1)
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        // Add book-like appearance
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = PapyrusDesignSystem.Colors.ancientInk.withAlphaComponent(0.2).cgColor
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.body()
        label.textColor = PapyrusDesignSystem.Colors.primaryText
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        return label
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = PapyrusDesignSystem.Colors.goldLeaf
        progress.trackTintColor = PapyrusDesignSystem.Colors.secondaryText.withAlphaComponent(0.2)
        progress.isHidden = true
        return progress
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = PapyrusDesignSystem.Typography.caption1()
        label.textColor = PapyrusDesignSystem.Colors.secondaryText
        label.textAlignment = .right
        label.isHidden = true
        return label
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = PapyrusDesignSystem.Colors.secondaryText.withAlphaComponent(0.5)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(bookSpineView)
        containerView.addSubview(coverImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(statusLabel)
        containerView.addSubview(chevronImageView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        bookSpineView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Book spine (left edge)
            bookSpineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            bookSpineView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            bookSpineView.widthAnchor.constraint(equalToConstant: 4),
            bookSpineView.heightAnchor.constraint(equalToConstant: 76),
            
            // Cover image (left side)
            coverImageView.leadingAnchor.constraint(equalTo: bookSpineView.trailingAnchor, constant: 2),
            coverImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 54),
            coverImageView.heightAnchor.constraint(equalToConstant: 76),
            
            // Chevron (right side)
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            // Progress
            progressView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 120),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),
            
            // Status
            statusLabel.centerYAnchor.constraint(equalTo: subtitleLabel.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with book: Book, progress: BookProgress?, beliefSystem: BeliefSystem? = nil) {
        titleLabel.text = book.title
        
        // Set subtitle with reading time
        let hours = book.estimatedReadingTime / 60
        let minutes = book.estimatedReadingTime % 60
        if hours > 0 {
            subtitleLabel.text = "\(hours)h \(minutes)m estimated reading time"
        } else {
            subtitleLabel.text = "\(minutes)m estimated reading time"
        }
        
        // Set cover image with belief system icon
        if let beliefSystem = beliefSystem {
            coverImageView.image = IconProvider.beliefSystemIcon(for: beliefSystem.icon, color: UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf)
            coverImageView.tintColor = UIColor(hex: beliefSystem.color) ?? PapyrusDesignSystem.Colors.goldLeaf
        } else {
            coverImageView.image = UIImage(systemName: "book.closed.fill")
            coverImageView.tintColor = PapyrusDesignSystem.Colors.goldLeaf
        }
        
        if let progress = progress {
            progressView.isHidden = false
            progressView.progress = Float(progress.readingProgress)
            
            if progress.isCompleted {
                statusLabel.isHidden = false
                statusLabel.text = "Completed"
                statusLabel.textColor = PapyrusDesignSystem.Colors.goldLeaf
            } else {
                statusLabel.isHidden = false
                statusLabel.text = "\(Int(progress.readingProgress * 100))%"
                statusLabel.textColor = PapyrusDesignSystem.Colors.secondaryText
            }
        } else {
            progressView.isHidden = true
            statusLabel.isHidden = true
        }
        
        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        statusLabel.text = nil
        progressView.progress = 0
        progressView.isHidden = true
        statusLabel.isHidden = true
        coverImageView.image = nil
        setNeedsLayout()
        layoutIfNeeded()
    }
}