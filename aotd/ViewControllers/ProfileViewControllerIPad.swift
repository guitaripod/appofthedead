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
        contentMaxWidthConstraint?.constant = layoutManager.screenWidth > 1024 ? 800 : ProfileViewController.uncappedContentWidth
        contentStackView.spacing = layoutManager.spacing(for: .extraLarge, traitCollection: traitCollection)
    }

    private func enhanceVisualElements() {
        let layoutManager = AdaptiveLayoutManager.shared
        if layoutManager.isIPad {
            ringWidthConstraint?.constant = 120
            ringHeightConstraint?.constant = 120
            avatarWidthConstraint?.constant = 80
            avatarHeightConstraint?.constant = 80
            avatarImageView.layer.cornerRadius = 40
            xpRingView.setNeedsLayout()
        }
        for view in [profileHeaderView, statsContainerView, streakCard] {
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
        levelLabel.font = PapyrusDesignSystem.Typography.headline(weight: .semibold, for: traitCollection)
        xpLabel.font = PapyrusDesignSystem.Typography.subheadline(for: traitCollection)
        achievementsHeaderLabel.font = PapyrusDesignSystem.Typography.title1(for: traitCollection)
    }

    private func addPointerInteractions() {
        profileHeaderView.addCardPointerInteraction()
        streakCard.addCardPointerInteraction()
        statsStackView.arrangedSubviews.forEach { row in
            (row as? UIStackView)?.arrangedSubviews.forEach { $0.addCardPointerInteraction() }
        }
        pathTrophyCollectionView.visibleCells.forEach { $0.addCardPointerInteraction() }
        achievementsCollectionView.visibleCells.forEach { $0.addCardPointerInteraction() }
    }

    func updateForTraitCollection() {
        updateLayoutForIPad()
    }
}
