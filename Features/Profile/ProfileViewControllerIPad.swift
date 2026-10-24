import UIKit

extension ProfileViewController {
    func updateLayoutForIPad() {
        let layoutManager = AdaptiveLayoutManager.shared
        if layoutManager.usesTabletLayout(traitCollection) && layoutManager.isRegularWidth(traitCollection) {
            setupIPadLayout()
            enhanceVisualElements()
            addPointerInteractions()
        } else {
            restorePhoneLayout()
        }
    }

    /// A window that narrows after being wide, such as the folding iPhone closing, goes back to the
    /// phone metrics instead of keeping the tablet ones.
    private func restorePhoneLayout() {
        scrollView.contentInset = .zero
        contentMaxWidthConstraint?.constant = ProfileViewController.uncappedContentWidth
        contentStackView.spacing = 24
        ringWidthConstraint?.constant = 96
        ringHeightConstraint?.constant = 96
        avatarWidthConstraint?.constant = 64
        avatarHeightConstraint?.constant = 64
        avatarImageView.layer.cornerRadius = 32
        nameLabel.font = UIFont(name: "Papyrus", size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
        levelLabel.font = PapyrusDesignSystem.Typography.subheadline(weight: .semibold)
        xpLabel.font = PapyrusDesignSystem.Typography.footnote()
        achievementsHeaderLabel.font = PapyrusDesignSystem.Typography.title2()
        xpRingView.setNeedsLayout()
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
        contentMaxWidthConstraint?.constant = (view.window?.bounds.width ?? view.bounds.width) > 1024 ? 800 : ProfileViewController.uncappedContentWidth
        contentStackView.spacing = layoutManager.spacing(for: .extraLarge, traitCollection: traitCollection)
    }

    private func enhanceVisualElements() {
        let layoutManager = AdaptiveLayoutManager.shared
        if layoutManager.usesTabletLayout(traitCollection) {
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
