#if DEBUG
import UIKit
import MidgarKit
import AppOfTheDeadCore

/// Walks the app's heaviest screens with the frame watch running, so each screen gets its own stretch and its own
/// picture. `AOTD_DEMO_WALK=1` runs it; every screen is opened without animation, named in the log, held long enough to
/// settle, scrolled once where it scrolls, and drawn into `Library/Logs/frames`. The same walk runs again after a fix,
/// so the two runs are compared screen for screen.
@MainActor
final class DemoWalk {

    /// One screen of the walk, with the pacing every run shares.
    private enum Screen: String, CaseIterable {
        case home = "Home"
        case pathMap = "Path map"
        case lesson = "Lesson"
        case homeReturn = "Home (return)"
        case reader = "Reader"
        case oracle = "Oracle"
        case paywall = "Paywall"

        var scrolls: Bool {
            switch self {
            case .home, .homeReturn, .reader, .oracle: return true
            case .pathMap, .lesson, .paywall: return false
            }
        }
    }

    private enum Pacing {
        /// Time a screen holds still before anything moves on it.
        static let settle: TimeInterval = 2.2
        /// Time a screen holds after its one scroll, so the scroll animation finishes inside the stretch.
        static let afterScroll: TimeInterval = 1.3
        /// Time between one screen being left and the next being opened.
        static let betweenScreens: TimeInterval = 0.3
    }

    private static var active: DemoWalk?

    nonisolated static var isRequested: Bool {
        ProcessInfo.processInfo.environment["AOTD_DEMO_WALK"] == "1"
    }

    private let context: DemoContext
    private let screens = Screen.allCases
    private var index = 0

    private init(context: DemoContext) {
        self.context = context
    }

    static func start(context: DemoContext) {
        let walk = DemoWalk(context: context)
        active = walk
        walk.begin()
    }

    private func begin() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Pacing.betweenScreens) { [weak self] in
            MidgarFrameWatch.shared.report("Launch")
            self?.enterCurrentScreen()
        }
    }

    private func enterCurrentScreen() {
        guard index < screens.count else {
            finish()
            return
        }
        let screen = screens[index]
        open(screen)
        DispatchQueue.main.asyncAfter(deadline: .now() + Pacing.settle) { [weak self] in
            self?.scrollIfNeeded(screen)
        }
    }

    private func scrollIfNeeded(_ screen: Screen) {
        if screen.scrolls {
            Self.scrollOnce(in: currentWindow())
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Pacing.afterScroll) { [weak self] in
            self?.holdCurrentScreen(screen)
        }
    }

    private func holdCurrentScreen(_ screen: Screen) {
        let name = screen.rawValue
        let number = index
        capture(name: name, number: number)
        MidgarFrameWatch.shared.disregardWhatJustRan()
        MidgarFrameWatch.shared.report(name)
        DispatchQueue.main.asyncAfter(deadline: .now() + Pacing.betweenScreens) { [weak self] in
            guard let self else { return }
            self.leave(screen)
            self.index += 1
            self.enterCurrentScreen()
        }
    }

    private func finish() {
        MidgarLog.notice("Demo walk finished", category: .ui)
    }

    private func open(_ screen: Screen) {
        switch screen {
        case .home:
            context.root.dismiss(animated: false)
            context.homeNavigation.popToRootViewController(animated: false)
            context.root.selectViewController(at: 0)
        case .homeReturn:
            context.homeNavigation.popToRootViewController(animated: false)
            context.root.selectViewController(at: 0)
        case .pathMap:
            guard let system = beliefSystem("norse") else { return }
            context.homeViewModel.onPathSelected?(system)
        case .lesson:
            guard let system = beliefSystem("norse"), let lesson = system.lessons.first else { return }
            let viewModel = LessonViewModel(
                lesson: lesson,
                beliefSystem: system,
                currentLessonIndex: 0,
                totalLessons: system.lessons.count
            )
            context.homeNavigation.pushViewController(LessonViewController(viewModel: viewModel), animated: false)
        case .reader:
            guard let user = DatabaseManager.shared.fetchUser(),
                  let book = try? DatabaseManager.shared.getBook(by: "book_norse") else { return }
            let reader = BookReaderViewController(viewModel: BookReaderViewModel(book: book, userId: user.id))
            reader.modalPresentationStyle = .fullScreen
            context.root.present(reader, animated: false)
        case .oracle:
            context.root.selectViewController(at: 2)
        case .paywall:
            context.root.present(PaywallViewController(reason: .generalUpgrade), animated: false)
        }
    }

    private func leave(_ screen: Screen) {
        switch screen {
        case .pathMap:
            context.homeNavigation.popToRootViewController(animated: false)
        case .reader, .paywall:
            context.root.dismiss(animated: false)
        case .home, .homeReturn, .lesson, .oracle:
            break
        }
    }

    private func beliefSystem(_ id: String) -> BeliefSystem? {
        context.contentLoader.loadBeliefSystems().first { $0.id == id }
    }

    private func currentWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    /// Draws what is on screen into the log folder the runner pulls back, so the pixels of every screen can be looked
    /// at after a run.
    private func capture(name: String, number: Int) {
        guard let window = currentWindow(), window.bounds.width > 0 else { return }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        guard let data = image.pngData() else { return }
        let directory = Self.frameDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: directory.appendingPathComponent(Self.fileName(name, number: number)))
    }

    private static func fileName(_ name: String, number: Int) -> String {
        let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
        return "\(String(format: "%02d", number))-\(slug).png"
    }

    private static var frameDirectory: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return library.appendingPathComponent("Logs/frames", isDirectory: true)
    }

    /// Scrolls the first scrollable view on screen by a little under a screenful, so a list's per-row work runs inside
    /// the stretch. Bounded to what the content allows.
    private static func scrollOnce(in window: UIWindow?) {
        guard let window, let scrollView = firstScrollableView(in: window) else { return }
        let inset = scrollView.adjustedContentInset
        let limit = max(-inset.top, scrollView.contentSize.height - scrollView.bounds.height + inset.bottom)
        let target = min(scrollView.contentOffset.y + 380, limit)
        guard target > scrollView.contentOffset.y + 1 else { return }
        UIView.animate(withDuration: 0.7, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            scrollView.contentOffset.y = target
        }
    }

    private static func firstScrollableView(in view: UIView) -> UIScrollView? {
        var queue = [view]
        while let next = queue.first {
            queue.removeFirst()
            if let scrollView = next as? UIScrollView,
               !scrollView.isHidden,
               scrollView.alpha > 0,
               scrollView.contentSize.height > scrollView.bounds.height + 40 {
                return scrollView
            }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }
}
#endif
