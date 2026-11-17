import Foundation
import MidgarCore

/// Which generative features this device offers. Apple's China mainland AI declarations answer No when on-device
/// generation is off, so an account there loses the Oracle and every model-written text, and keeps the rest of the app.
nonisolated struct GenerativeFeatureVisibility: Equatable, Sendable {
    let onDeviceGeneration: Bool

    static var current: GenerativeFeatureVisibility {
        GenerativeFeatureVisibility(onDeviceGeneration: MidgarModelRegion.shared.onDeviceGenerationAvailable)
    }

    /// The Oracle tab and everything that leads to it: the Judgment's guide, the deep link, Settings' voice and the
    /// Oracle copy in offers, paywalls and the membership card.
    var showsOracle: Bool { onDeviceGeneration }

    /// Lesson terms explained by a model, the book's Ask Oracle action and the explanations those open.
    var showsModelWrittenText: Bool { onDeviceGeneration }
}
