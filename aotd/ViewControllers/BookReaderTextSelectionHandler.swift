import UIKit

protocol BookReaderTextSelectionDelegate: AnyObject {
    func textSelectionHandler(_ handler: BookReaderTextSelectionHandler, didSelectAction action: TextSelectionAction, text: String, range: NSRange)
}

enum TextSelectionAction {
    case askOracle
    case highlight(color: UIColor)
    case addNote
    case copy
    case share
    case define
}

final class BookReaderTextSelectionHandler: NSObject {
    
    
    
    weak var delegate: BookReaderTextSelectionDelegate?
    private weak var textView: UITextView?
    private var customMenuItems: [UIMenuItem] = []
    
    
    
    init(textView: UITextView) {
        self.textView = textView
        super.init()
        setupMenuItems()
    }
    
    
    
    private func setupMenuItems() {
        
        let askOracleItem = UIMenuItem(title: "Ask Oracle 🔮", action: #selector(askOracle))
        let highlightYellowItem = UIMenuItem(title: "Highlight", action: #selector(highlightYellow))
        let highlightBlueItem = UIMenuItem(title: "Blue", action: #selector(highlightBlue))
        let highlightGreenItem = UIMenuItem(title: "Green", action: #selector(highlightGreen))
        let addNoteItem = UIMenuItem(title: "Add Note 📝", action: #selector(addNote))
        let shareItem = UIMenuItem(title: "Share", action: #selector(share))
        
        customMenuItems = [
            askOracleItem,
            highlightYellowItem,
            highlightBlueItem,
            highlightGreenItem,
            addNoteItem,
            shareItem
        ]
        
        
        UIMenuController.shared.menuItems = customMenuItems
    }
    
    
    
    func configureTextView() {
        
        textView?.isUserInteractionEnabled = true
        textView?.isSelectable = true
        
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        textView?.addGestureRecognizer(longPressGesture)
    }
    
    
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let textView = textView else { return }
        
        let point = gesture.location(in: textView)
        
        
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        let locationInTextContainer = CGPoint(
            x: point.x - textView.textContainerInset.left,
            y: point.y - textView.textContainerInset.top
        )
        
        let characterIndex = layoutManager.characterIndex(
            for: locationInTextContainer,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        
        
        if textView.selectedRange.length > 0 {
            showCustomMenu()
        } else {
            
            selectWord(at: characterIndex)
        }
    }
    
    private func selectWord(at index: Int) {
        guard let textView = textView,
              index < textView.text.count else { return }
        
        let text = textView.text as NSString
        
        
        let tokenizer = UITextInputStringTokenizer(textInput: textView)
        let position = textView.position(from: textView.beginningOfDocument, offset: index) ?? textView.beginningOfDocument
        
        
        let wordStart = tokenizer.position(from: position, toBoundary: .word, inDirection: .layout(.left)) ?? position
        let wordEnd = tokenizer.position(from: position, toBoundary: .word, inDirection: .layout(.right)) ?? position
        
        let startOffset = textView.offset(from: textView.beginningOfDocument, to: wordStart)
        let endOffset = textView.offset(from: textView.beginningOfDocument, to: wordEnd)
        
        var wordRange = NSRange(location: startOffset, length: endOffset - startOffset)
        
        
        if wordRange.length == 0 {
            let range = text.rangeOfComposedCharacterSequence(at: index)
            var start = range.location
            var end = range.location + range.length
            
            
            while start > 0 {
                let charRange = NSRange(location: start - 1, length: 1)
                let char = text.substring(with: charRange)
                if char.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
                    break
                }
                start -= 1
            }
            
            
            while end < text.length {
                let charRange = NSRange(location: end, length: 1)
                let char = text.substring(with: charRange)
                if char.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
                    break
                }
                end += 1
            }
            
            wordRange = NSRange(location: start, length: end - start)
        }
        
        textView.selectedRange = wordRange
        
        
        showCustomMenu()
    }
    
    private func showCustomMenu() {
        guard let textView = textView else { return }
        
        textView.becomeFirstResponder()
        
        let menuController = UIMenuController.shared
        
        
        let selectedRange = textView.selectedRange
        let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
        let rect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
        
        let menuRect = CGRect(
            x: rect.origin.x + textView.textContainerInset.left,
            y: rect.origin.y + textView.textContainerInset.top,
            width: rect.width,
            height: rect.height
        )
        
        if #available(iOS 13.0, *) {
            menuController.showMenu(from: textView, rect: menuRect)
        } else {
            menuController.setTargetRect(menuRect, in: textView)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func askOracle() {
        handleAction(.askOracle)
    }
    
    @objc func highlightYellow() {
        handleAction(.highlight(color: PapyrusDesignSystem.Colors.goldLeaf))
    }
    
    @objc func highlightBlue() {
        handleAction(.highlight(color: UIColor.systemBlue.withAlphaComponent(0.3)))
    }
    
    @objc func highlightGreen() {
        handleAction(.highlight(color: UIColor.systemGreen.withAlphaComponent(0.3)))
    }
    
    @objc func addNote() {
        handleAction(.addNote)
    }
    
    @objc func share() {
        handleAction(.share)
    }
    
    private func handleAction(_ action: TextSelectionAction) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0 else { return }
        
        let selectedText = (textView.text as NSString).substring(with: selectedRange)
        
        
        if #available(iOS 13.0, *) {
            UIMenuController.shared.hideMenu()
        } else {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
        
        
        delegate?.textSelectionHandler(self, didSelectAction: action, text: selectedText, range: selectedRange)
    }
}



class BookReaderTextView: UITextView {
    weak var selectionHandler: BookReaderTextSelectionHandler?
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        let customActions: [Selector] = [
            #selector(askOracle),
            #selector(highlightYellow),
            #selector(highlightBlue),
            #selector(highlightGreen),
            #selector(addNote),
            #selector(share)
        ]
        
        if customActions.contains(action) {
            return selectedRange.length > 0
        }
        
        
        let standardActions: [Selector] = [
            #selector(copy(_:)),
            #selector(select(_:)),
            #selector(selectAll(_:))
        ]
        
        if standardActions.contains(action) {
            return super.canPerformAction(action, withSender: sender)
        }
        
        
        if action == NSSelectorFromString("_define:") {
            return selectedRange.length > 0
        }
        
        return false
    }
    
    
    @objc func askOracle() {
        selectionHandler?.askOracle()
    }
    
    @objc func highlightYellow() {
        selectionHandler?.highlightYellow()
    }
    
    @objc func highlightBlue() {
        selectionHandler?.highlightBlue()
    }
    
    @objc func highlightGreen() {
        selectionHandler?.highlightGreen()
    }
    
    @objc func addNote() {
        selectionHandler?.addNote()
    }
    
    @objc func share() {
        selectionHandler?.share()
    }
}