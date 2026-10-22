import UIKit

extension BookReaderViewController: BookReaderSettingsDelegate {
    func settingsDidUpdateFontSize(_ size: Double) {
        viewModel.updateFontSize(size)
    }
    
    func settingsDidUpdateBrightness(_ brightness: Double) {
        viewModel.updateBrightness(brightness)
        view.alpha = CGFloat(brightness)
    }
    
    func settingsDidUpdateTTSSpeed(_ speed: Float) {
        viewModel.updateTTSSpeed(speed)

        speechRestartWorkItem?.cancel()
        guard let synthesizer = speechSynthesizer, synthesizer.isSpeaking, !synthesizer.isPaused else { return }

        let restart = DispatchWorkItem { [weak self] in
            guard let self,
                  let synthesizer = self.speechSynthesizer,
                  synthesizer.isSpeaking, !synthesizer.isPaused else { return }
            let resumeOffset = self.spokenCharacterOffset
            self.stopSpeech()
            self.startSpeech(fromOffset: resumeOffset)
        }
        speechRestartWorkItem = restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: restart)
    }
    
    func settingsDidUpdateAutoScrollSpeed(_ speed: Double) {
        viewModel.updateAutoScrollSpeed(speed)
        
        if autoScrollTimer != nil {
            stopAutoScroll()
            startAutoScroll()
        }
    }
    
    func settingsDidUpdateFontFamily(_ family: String) {
        viewModel.preferences.fontFamily = family
        updateContent()
    }
    
    func settingsDidUpdateFontWeight(_ weight: String) {
        viewModel.preferences.fontWeight = weight
        updateContent()
    }
    
    func settingsDidUpdateLineSpacing(_ spacing: Double) {
        viewModel.preferences.lineSpacing = spacing
        updateContent()
    }
    
    func settingsDidUpdateParagraphSpacing(_ spacing: Double) {
        viewModel.preferences.paragraphSpacing = spacing
        updateContent()
    }
    
    func settingsDidUpdateFirstLineIndent(_ indent: Double) {
        viewModel.preferences.firstLineIndent = indent
        updateContent()
    }
    
    func settingsDidUpdateTextAlignment(_ alignment: String) {
        viewModel.preferences.textAlignment = alignment
        updateContent()
    }
    
    func settingsDidUpdateMargins(_ size: Double) {
        viewModel.preferences.marginSize = size
        applyTextAlignment()
    }
    
    func settingsDidUpdateTheme(_ theme: String) {
        viewModel.preferences.theme = theme
        applyReadingPreferences()
    }
    
    func settingsDidUpdateHyphenation(_ enabled: Bool) {
        viewModel.preferences.enableHyphenation = enabled
        updateContent()
    }
    
    func settingsDidUpdatePageProgress(_ enabled: Bool) {
        viewModel.preferences.showPageProgress = enabled
        progressView.isHidden = !enabled
        percentageLabel.isHidden = !enabled
    }
    
    func settingsDidUpdateKeepScreenOn(_ enabled: Bool) {
        viewModel.preferences.keepScreenOn = enabled
        UIApplication.shared.isIdleTimerDisabled = enabled
    }
    
    func settingsDidUpdateSwipeGestures(_ enabled: Bool) {
        viewModel.preferences.enableSwipeGestures = enabled
        
    }
    
    func settingsDidUpdatePageTransition(_ style: String) {
        viewModel.preferences.pageTransitionStyle = style
        
    }
}
