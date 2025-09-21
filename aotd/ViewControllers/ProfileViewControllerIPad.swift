import UIKit
extension ProfileViewController {
    func updateLayoutForIPad() {
        guard AdaptiveLayoutManager.shared.isIPad else { return }
        if AdaptiveLayoutManager.shared.isRegularWidth(traitCollection) {
            setupIPadLayout()
            enhanceVisualElements()
            addPointerInteractions()
        }
    }
    private func setupIPadLayout() {
        let layoutManager = AdaptiveLayoutManager.shared
        let insets = layoutManager.contentInsets(for: traitCollection)
        scrollView.contentInset = UIEdgeInsets(
            top: insets.top,
            left: 0,
            bottom: insets.bottom,
            right: 0
        )
        if layoutManager.screenWidth > 1024 {
            let maxWidth: CGFloat = 800
            let horizontalPadding = (layoutManager.screenWidth - maxWidth) / 2
            contentStackView.constraints.forEach { constraint in
                if constraint.firstAttribute == .leading {
                    constraint.constant = max(20, horizontalPadding)
                } else if constraint.firstAttribute == .trailing {
                    constraint.constant = min(-20, -horizontalPadding)
                }
            }
        }
        contentStackView.spacing = layoutManager.spacing(for: .extraLarge, traitCollection: traitCollection)
    }
    private func enhanceVisualElements() {
        let layoutManager = AdaptiveLayoutManager.shared
        if layoutManager.isIPad {
            for constraint in avatarImageView.superview?.constraints ?? [] {
                if (constraint.firstItem as? UIView) == avatarImageView {
                    if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                        constraint.constant = 120 
                    }
                }
            }
            avatarImageView.layer.cornerRadius = 60
        }
        for view in [profileHeaderView, statsContainerView] {
            let shadow = PapyrusDesignSystem.Shadow.elevated()
            view.layer.shadowColor = shadow.color
            view.layer.shadowOpacity = shadow.opacity
            view.layer.shadowOffset = shadow.offset
            view.layer.shadowRadius = shadow.radius
        }
        updateFontsForIPad()
    }
    private func updateFontsForIPad() {
        nameLabel.font = PapyrusDesignSystem.Typography.largeTitle(for: traitCollection)
        levelLabel.font = PapyrusDesignSystem.Typography.title2(for: traitCollection)
        xpLabel.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
        achievementsHeaderLabel.font = PapyrusDesignSystem.Typography.title1(for: traitCollection)
        statsStackView.arrangedSubviews.forEach { statCard in
            if let stackView = statCard as? UIStackView {
                stackView.arrangedSubviews.forEach { view in
                    if let label = view as? UILabel {
                        if label.font.pointSize > 20 {
                            label.font = PapyrusDesignSystem.Typography.largeTitle(for: traitCollection)
                        } else {
                            label.font = PapyrusDesignSystem.Typography.headline(for: traitCollection)
                        }
                    }
                }
            }
        }
    }
    private func addPointerInteractions() {
        if #available(iOS 13.4, *) {
            statsStackView.arrangedSubviews.forEach { view in
                view.addCardPointerInteraction()
            }
            achievementsCollectionView.visibleCells.forEach { cell in
                cell.addCardPointerInteraction()
            }
            profileHeaderView.addCardPointerInteraction()
        }
    }
    func updateForTraitCollection() {
        updateLayoutForIPad()
    }
}