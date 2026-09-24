import Foundation

/// Routes the app opens from `appofthedead://` URLs, such as the one on an App Store in-app event.
enum DeepLink: Equatable {
    case path(beliefSystemId: String)

    static let scheme = "appofthedead"

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              url.host?.lowercased() == "path",
              let beliefSystemId = url.pathComponents.first(where: { $0 != "/" }),
              !beliefSystemId.isEmpty else { return nil }
        self = .path(beliefSystemId: beliefSystemId)
    }
}
