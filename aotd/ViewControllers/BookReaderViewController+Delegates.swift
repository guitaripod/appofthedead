import AVFoundation
import UIKit
import MidgarCore

extension BookReaderViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height > 0 else { return }
        guard !isNavigatingChapter else { return } 
        guard hasRestoredPosition else { return } 
        
        
        
        
        
        let currentOffset = scrollView.contentOffset.y + scrollView.bounds.height / 2
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        
        let point = CGPoint(x: textView.bounds.midX, y: currentOffset)
        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        
        var currentChapter = 0
        for (index, startPosition) in chapterStartPositions.enumerated() {
            if characterIndex >= startPosition {
                currentChapter = index
            } else {
                break
            }
        }
        
        
        if currentChapter != viewModel.currentChapterIndex && currentChapter < viewModel.book.chapters.count {
            viewModel.updateCurrentChapter(currentChapter)
            chapterLabel.text = String(localized: "Chapter \(currentChapter + 1) of \(viewModel.book.chapters.count): \(viewModel.currentChapterTitle)")
            updateChapterInfo()
            
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        
        if currentChapter < chapterStartPositions.count {
            let chapterStart = chapterStartPositions[currentChapter]
            let chapterEnd: Int
            
            if currentChapter < chapterStartPositions.count - 1 {
                chapterEnd = chapterStartPositions[currentChapter + 1]
            } else {
                chapterEnd = textView.text.count
            }
            
            let chapterLength = chapterEnd - chapterStart
            if chapterLength > 0 {
                let progressInChapter = Double(characterIndex - chapterStart) / Double(chapterLength)
                let clampedProgress = max(0, min(1, progressInChapter))
                
                
                viewModel.updateScrollPosition(clampedProgress)
                
                
                
            }
        }
    }
}

extension BookReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension BookReaderViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if viewModel.canGoNext {
            viewModel.goToNextChapter()
            startSpeech()
        } else {
            speechButton.setImage(UIImage(systemName: "speaker.wave.2"), for: .normal)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        spokenCharacterOffset = speechTextBase + characterRange.location
    }
}

extension BookReaderViewController: BookReaderTextSelectionDelegate {
    func textSelectionHandler(_ handler: BookReaderTextSelectionHandler, didSelectAction action: TextSelectionAction, text: String, range: NSRange) {
        switch action {
        case .askOracle:
            showOracleExplanation(for: text, range: range)
            
        case .highlight(let color):
            saveHighlight(text: text, range: range, color: color)
            
        case .addNote:
            showNoteEditor(for: text, range: range)
            
        case .copy:
            UIPasteboard.general.string = text
            
        case .share:
            shareText(text)
            
        case .define:
            
            break
        }
    }
}

extension BookReaderViewController: OracleTextExplanationViewDelegate {
    func oracleTextExplanationViewDidDismiss(_ view: OracleTextExplanationView) {
        activeOracleExplanation = nil
    }

    func oracleTextExplanationView(_ view: OracleTextExplanationView, didSaveExplanation explanation: String, for text: String) {
        activeOracleExplanation = nil

        if let range = textView.text.range(of: text) {
            let nsRange = NSRange(range, in: textView.text)


            Task {
                do {
                guard let user = DatabaseManager.shared.fetchUser() else { return }


                    let consultation = OracleConsultation(
                        userId: user.id,
                        deityId: oracleDeityId()
                    )

                    try DatabaseManager.shared.saveOracleConsultation(consultation)
                    
                    
                    saveHighlight(
                        text: text,
                        range: nsRange,
                        color: PapyrusDesignSystem.Colors.goldLeaf,
                        note: nil,
                        oracleConsultationId: consultation.id
                    )
                    
                } catch {
                    MidgarLog.error("Failed to save oracle consultation: \(error)", category: .database)
                }
            }
        }
    }
}
