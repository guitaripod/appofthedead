import UIKit
import MidgarUI

/// The open-source software inside App of the Dead and the terms of the models the Oracle can download.
enum Licenses {
    private struct Component {
        let name: String
        let license: String
        let url: URL
    }

    private static let components: [Component] = [
        Component(name: "GRDB.swift", license: "MIT", url: URL(string: "https://github.com/groue/GRDB.swift")!),
        Component(name: "MLX Swift", license: "MIT", url: URL(string: "https://github.com/ml-explore/mlx-swift")!),
        Component(name: "MLX Swift LM", license: "MIT", url: URL(string: "https://github.com/ml-explore/mlx-swift-lm")!),
        Component(name: "Swift Transformers", license: "Apache 2.0", url: URL(string: "https://github.com/huggingface/swift-transformers")!),
        Component(name: "Swift Hugging Face", license: "Apache 2.0", url: URL(string: "https://github.com/huggingface/swift-huggingface")!),
        Component(name: "Swift Jinja", license: "Apache 2.0", url: URL(string: "https://github.com/huggingface/swift-jinja")!),
        Component(name: "EventSource", license: "MIT", url: URL(string: "https://github.com/mattt/EventSource")!),
        Component(name: "yyjson", license: "MIT", url: URL(string: "https://github.com/ibireme/yyjson")!),
        Component(name: "SwiftNIO", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-nio")!),
        Component(name: "Swift Crypto", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-crypto")!),
        Component(name: "Swift ASN.1", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-asn1")!),
        Component(name: "Swift Collections", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-collections")!),
        Component(name: "Swift Atomics", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-atomics")!),
        Component(name: "Swift Numerics", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-numerics")!),
        Component(name: "Swift System", license: "Apache 2.0", url: URL(string: "https://github.com/apple/swift-system")!),
    ]

    static func makeViewController() -> UIViewController {
        MidgarSettingsViewController(title: String(localized: "Licenses"), sections: sections(), theme: .aotd)
    }

    private static func sections() -> [MidgarSettingsSection] {
        [
            MidgarSettingsSection(
                id: "models",
                title: String(localized: "Oracle Models"),
                footer: String(localized: "On iPhones without Apple Intelligence the Oracle downloads Gemma 4, available under the Apache 2.0 license, or on iPhones with less memory Gemma 3, provided under and subject to the Gemma Terms of Use."),
                rows: [
                    .link(id: "gemma4", title: "Gemma 4 · Apache 2.0", systemImage: "cpu", url: URL(string: "https://ai.google.dev/gemma/docs/core")!),
                    .link(id: "gemmaTerms", title: String(localized: "Gemma Terms of Use"), systemImage: "doc.text", url: URL(string: "https://ai.google.dev/gemma/terms")!),
                ]
            ),
            MidgarSettingsSection(
                id: "software",
                title: String(localized: "Open-Source Software"),
                footer: String(localized: "Each project's page holds its full license text."),
                rows: components.map { component in
                    MidgarSettingsRow(
                        id: component.name,
                        title: component.name,
                        detail: component.license,
                        kind: .link(component.url),
                        showsDisclosure: true
                    )
                }
            ),
        ]
    }
}
