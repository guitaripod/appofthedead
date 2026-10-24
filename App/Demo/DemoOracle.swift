#if DEBUG
import Foundation

/// Canned Oracle conversations so the chat screen is full without the on-device model.
enum DemoOracle {
    struct Conversation {
        let deity: OracleViewModel.Deity
        let messages: [OracleViewModel.ChatMessage]
    }

    private static let scripts: [String: [(isUser: Bool, text: String)]] = [
        "odin": [
            (true, "How do I earn a place in Valhalla?"),
            (false, "Valhalla opens for those who fall in battle with courage, but I weigh more than blades. I hung nine nights on Yggdrasil, wounded by my own spear, to learn that **wisdom is bought with sacrifice**.\n\nThe Valkyries choose half of the slain. Freyja takes the rest to Folkvangr."),
            (true, "And everyone else?"),
            (false, "Those who die of sickness or age go to Hel's quiet halls, which is no punishment. Only oath-breakers and murderers are sent to Nastrond.\n\nSo live in a way that is worth singing about:\n- keep your word\n- honor your guests\n- face your fate without flinching")
        ],
        "anubis": [
            (true, "What happens at the weighing of the heart?"),
            (false, "Your heart is set on one side of my scales, and the feather of Ma'at on the other. If your heart is **light with truth**, Thoth records the verdict and Osiris welcomes you to the Field of Reeds.\n\nIf it is heavy with lies, Ammit waits beneath the scales."),
            (true, "Can the heart be prepared?"),
            (false, "It can. The scribes who wrote the Book of Coming Forth by Day gave the dead forty-two declarations to speak. But a spell cannot replace a life lived fairly. Tend your heart now, and the scales will hold no fear for you.")
        ],
        "hecate": [
            (true, "Why are you called the keeper of keys?"),
            (false, "I stand where roads divide, and every threshold has a lock. I carry the keys between the living world, the sea and the underworld, so that I may *open* a way or close it.\n\nThose who lose their path call my name at the crossroads at night."),
            (true, "What should I leave you at a crossroads?"),
            (false, "Honey, garlic and bread, set down without looking back. The offering matters less than the quiet you carry away from the place.")
        ]
    ]

    static var requestedDeityId: String? {
        ProcessInfo.processInfo.environment["AOTD_DEMO_DEITY"]
    }

    static func conversation(for deities: [OracleViewModel.Deity]) -> Conversation? {
        guard DemoWorld.isActive else { return nil }
        let id = requestedDeityId ?? "odin"
        guard let deity = deities.first(where: { $0.id == id }), let script = scripts[id] else { return nil }
        let start = Date().addingTimeInterval(-Double(script.count) * 60)
        let messages = script.enumerated().map { offset, line in
            OracleViewModel.ChatMessage(
                text: line.text,
                isUser: line.isUser,
                deity: line.isUser ? nil : deity,
                timestamp: start.addingTimeInterval(Double(offset) * 60)
            )
        }
        return Conversation(deity: deity, messages: messages)
    }
}
#endif
