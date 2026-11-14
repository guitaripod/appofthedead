import UIKit

/// Shows a reply that is still being written a few characters at a time on the display's beat, each new letter fading
/// in, so the Oracle's words arrive as a steady flow instead of in the model's bursts. The word being revealed is laid
/// out in full but kept clear, so lines never reflow as it completes.
final class OracleStreamReveal: NSObject {
    typealias Formatter = (String) -> NSAttributedString

    static let fadeDuration: CFTimeInterval = 0.2

    /// Called with the text to show whenever more of it becomes visible.
    var onUpdate: ((NSAttributedString) -> Void)?
    /// Called once, when the whole reply is on screen and settled.
    var onFinish: (() -> Void)?

    private let format: Formatter
    private var pacer = OracleStreamPacer()
    private var formatted = NSAttributedString()
    private var boundaries: [Int] = []
    private var revealTimes: [CFTimeInterval] = []
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private(set) var isFinished = false

    init(format: @escaping Formatter) {
        self.format = format
        super.init()
    }

    /// The reply as far as the model has written it; `isComplete` once it is whole.
    func update(text: String, isComplete: Bool) {
        guard !isFinished else { return }
        formatted = format(isComplete ? text : OracleTextFormatter.streamingSafe(text))
        boundaries = Self.characterBoundaries(of: formatted.string)
        pacer.setTarget(length: boundaries.count, isComplete: isComplete)
        if revealTimes.count > pacer.visibleLength {
            revealTimes.removeLast(revealTimes.count - pacer.visibleLength)
        }
        if UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning {
            pacer.revealAll()
            revealTimes = Array(repeating: 0, count: pacer.visibleLength)
            onUpdate?(visibleText(at: CACurrentMediaTime()))
            finishIfSettled(at: CACurrentMediaTime())
            return
        }
        startTicking()
    }

    /// What should be on screen right now.
    var visibleText: NSAttributedString {
        visibleText(at: CACurrentMediaTime())
    }

    /// Stops animating and forgets the reply; nothing more is reported.
    func cancel() {
        isFinished = true
        stopTicking()
        onUpdate = nil
        onFinish = nil
    }

    private func startTicking() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: WeakTarget(self), selector: #selector(WeakTarget.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTimestamp = nil
    }

    private func stopTicking() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }

    fileprivate func tick(_ link: CADisplayLink) {
        let now = link.targetTimestamp
        let elapsed = lastTimestamp.map { now - $0 } ?? link.duration
        lastTimestamp = now
        let before = pacer.visibleLength
        pacer.advance(by: elapsed)
        let after = pacer.visibleLength
        if after > before {
            revealTimes.append(contentsOf: Array(repeating: now, count: after - before))
        }
        let isFading = revealTimes.last.map { now - $0 < Self.fadeDuration } ?? false
        if after != before || isFading {
            onUpdate?(visibleText(at: now))
        }
        if finishIfSettled(at: now) { return }
        if pacer.isCaughtUp && !isFading {
            stopTicking()
        }
    }

    /// Reports the finished reply once every character is visible and has faded in.
    @discardableResult
    private func finishIfSettled(at now: CFTimeInterval) -> Bool {
        let isFading = revealTimes.last.map { now - $0 < Self.fadeDuration } ?? false
        guard pacer.isFinished, !isFading else { return false }
        isFinished = true
        stopTicking()
        onUpdate?(formatted)
        let finish = onFinish
        onUpdate = nil
        onFinish = nil
        finish?()
        return true
    }

    private func visibleText(at now: CFTimeInterval) -> NSAttributedString {
        let visible = pacer.visibleLength
        guard visible > 0 else { return NSAttributedString() }
        let length = boundaries[visible - 1]
        let text = NSMutableAttributedString(attributedString: formatted.attributedSubstring(from: NSRange(location: 0, length: length)))
        fadeNewestCharacters(of: text, visible: visible, at: now)
        appendRestOfCurrentWord(to: text, from: length)
        return text
    }

    /// The characters revealed in the last `fadeDuration` are drawn partly transparent, newest faintest.
    private func fadeNewestCharacters(of text: NSMutableAttributedString, visible: Int, at now: CFTimeInterval) {
        var index = min(visible, revealTimes.count) - 1
        while index >= 0 {
            let age = now - revealTimes[index]
            guard age < Self.fadeDuration else { break }
            let alpha = max(0.08, CGFloat(age / Self.fadeDuration))
            let start = index == 0 ? 0 : boundaries[index - 1]
            let range = NSRange(location: start, length: boundaries[index] - start)
            text.enumerateAttribute(.foregroundColor, in: range) { value, subrange, _ in
                let color = (value as? UIColor) ?? PapyrusDesignSystem.Colors.Dynamic.primaryText
                text.addAttribute(.foregroundColor, value: color.withAlphaComponent(color.cgColor.alpha * alpha), range: subrange)
            }
            index -= 1
        }
    }

    /// Lays out the unrevealed rest of the word in progress, invisible, so the line breaks where it finally will.
    private func appendRestOfCurrentWord(to text: NSMutableAttributedString, from location: Int) {
        let full = formatted.string as NSString
        guard location < full.length else { return }
        let whitespace = full.rangeOfCharacter(from: .whitespacesAndNewlines, options: [], range: NSRange(location: location, length: full.length - location))
        let end = whitespace.location == NSNotFound ? full.length : whitespace.location
        guard end > location else { return }
        let rest = NSMutableAttributedString(attributedString: formatted.attributedSubstring(from: NSRange(location: location, length: end - location)))
        rest.addAttribute(.foregroundColor, value: UIColor.clear, range: NSRange(location: 0, length: rest.length))
        text.append(rest)
    }

    /// The UTF-16 offset that ends each character of `string`, so a count of characters maps to a range in O(1).
    static func characterBoundaries(of string: String) -> [Int] {
        var boundaries: [Int] = []
        boundaries.reserveCapacity(string.count)
        var offset = 0
        for character in string {
            offset += character.utf16.count
            boundaries.append(offset)
        }
        return boundaries
    }
}

/// Holds the reveal weakly so its display link never keeps it alive.
private final class WeakTarget: NSObject {
    private weak var reveal: OracleStreamReveal?

    init(_ reveal: OracleStreamReveal) {
        self.reveal = reveal
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let reveal else {
            link.invalidate()
            return
        }
        reveal.tick(link)
    }
}
