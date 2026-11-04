import Foundation
import AppOfTheDeadCore

/// Builds what the Oracle's model is told: the deity's persona, the house rules, a few sentences from the tradition's
/// own lessons to keep its facts straight, and the last turns of the conversation.
enum OraclePrompt {

    struct Turn: Equatable {
        let question: String
        let answer: String
    }

    /// The learning paths a deity's knowledge is drawn from.
    static let pathsByDeity: [String: [String]] = [
        "anubis": ["egyptian-afterlife"],
        "hermes": ["greek-underworld"],
        "hecate": ["greek-underworld", "wicca"],
        "odin": ["norse"],
        "mictlantecuhtli": ["aztec-mictlan"],
        "ahura_mazda": ["zoroastrianism"],
        "yama": ["buddhism", "hinduism"],
        "kali": ["hinduism"],
        "azrael": ["islam"],
        "gabriel": ["judaism", "christianity", "islam"],
        "michael": ["anthroposophy", "christianity"],
        "meng_po": ["taoism"],
        "izanami": ["shinto"],
        "waheguru": ["sikhism"],
        "raven": ["native-american-visions"],
        "sophia": ["theosophy"],
        "emanuel": ["swedenborgian-visions"],
        "oyasama": ["tenrikyo"],
    ]

    static func instructions(persona: String, deityName: String, grounding: [String], mentionsSelfHarm: Bool = false) -> String {
        var text = """
        \(persona)

        You are \(deityName), speaking with a seeker in App of the Dead, an app that teaches how the world's religions and mythologies see death and the afterlife.
        Rules:
        - Stay in character as \(deityName), warm and vivid, and teach what your tradition believes.
        - Answer in two to five sentences, under 120 words.
        - Reply in the language the seeker writes in.
        - Describe teachings in your own words. Never quote scripture or give chapter and verse numbers.
        - When you are not sure of a fact, say what your tradition is unsure of instead of inventing names or numbers.
        - Speak only of your own tradition unless the seeker asks about another; then be brief and respectful.
        """
        if mentionsSelfHarm {
            text += "\n- The seeker asks about suicide. Answer gently and factually, never make death sound like an escape, and say that anyone struggling can reach a helpline or someone they trust."
        }
        if !grounding.isEmpty {
            text += "\n\nWhat your tradition's lessons in this app teach, for you to draw on:\n" + grounding.map { "- \($0)" }.joined(separator: "\n")
        }
        return text
    }

    static func prompt(question: String, history: [Turn]) -> String {
        guard !history.isEmpty else { return question }
        let earlier = history.suffix(2).map { "Seeker: \($0.question)\nYou: \(clipped($0.answer, to: 400))" }.joined(separator: "\n")
        return "Earlier in this conversation:\n\(earlier)\n\nThe seeker now says: \(question)"
    }

    /// Up to `limit` sentences from the deity's paths that share the most words with the question, or the opening
    /// of the first lesson when nothing matches.
    static func grounding(deityId: String, question: String, systems: [BeliefSystem], limit: Int = 5) -> [String] {
        let pathIds = pathsByDeity[deityId] ?? []
        let lessons = pathIds.compactMap { id in systems.first { $0.id == id } }.flatMap(\.lessons)
        let sentences = lessons.flatMap { sentencesOf($0.content) }
        guard !sentences.isEmpty else { return [] }
        let terms = keywords(in: question)
        let scored = sentences.enumerated().map { index, sentence in
            (index: index, sentence: sentence, score: keywords(in: sentence).intersection(terms).count)
        }
        let matches = scored.filter { $0.score > 0 }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
            .prefix(limit)
            .sorted { $0.index < $1.index }
            .map(\.sentence)
        if !matches.isEmpty { return matches.map { clipped($0, to: 280) } }
        return sentences.prefix(3).map { clipped($0, to: 280) }
    }

    static func sentencesOf(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            let sentence = (substring ?? "")
                .replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 20 { sentences.append(sentence) }
        }
        return sentences
    }

    /// Lower-cased words of three letters or more without a plural s, the cheap stand-in for meaning that matching
    /// needs.
    static func keywords(in text: String) -> Set<String> {
        Set(text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
            .map { $0.count > 4 && $0.hasSuffix("s") && !$0.hasSuffix("ss") ? String($0.dropLast()) : $0 })
    }

    /// Whether a question touches suicide, so the persona is told how to answer it.
    static func mentionsSelfHarm(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return ["suicid", "self-harm", "self harm", "selbstmord", "suizid", "自殺", "自杀", "자살", "samobój"].contains { lowered.contains($0) }
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "you", "are", "was", "why", "how", "who", "what", "when", "where", "which", "with",
        "would", "could", "should", "there", "their", "they", "them", "this", "that", "these", "those", "from",
        "have", "has", "had", "does", "did", "about", "into", "your", "yours", "will", "after", "tell", "were",
        "been", "being", "also", "only", "more", "most", "some", "such", "than", "then", "can", "not", "but",
        "all", "any", "our", "out", "his", "her", "its", "one", "get", "say", "said",
    ]

    private static func clipped(_ text: String, to length: Int) -> String {
        text.count > length ? String(text.prefix(length)) + "…" : text
    }
}

/// Spots a message that speaks of the person's own wish to die or to hurt themselves. Such a message never reaches a
/// persona: the app answers in its own voice, with help. Questions about what traditions teach of suicide pass, and the
/// persona's rules ask it to answer them gently.
enum CompassionGuard {
    private static let phrases: [String] = [
        "kill myself", "killing myself", "end my life", "ending my life", "take my own life", "want to die",
        "wanna die", "don't want to live", "dont want to live", "do not want to live", "suicidal", "hurt myself",
        "harm myself", "self harm", "self-harm", "cut myself", "better off dead", "no reason to live",
        "me suicider", "me tuer", "envie de mourir", "mich umbringen", "will sterben", "nicht mehr leben",
        "suicidarme", "matarme", "quiero morir", "quitarme la vida", "uccidermi", "voglio morire", "togliermi la vita",
        "me matar", "quero morrer", "tirar minha vida", "zabić się", "chcę umrzeć", "死にたい", "自殺したい", "消えたい",
        "죽고 싶", "자살하고", "我想死", "想自杀", "不想活", "想自殺",
    ]

    static func needsCare(_ message: String) -> Bool {
        let text = message.lowercased().replacingOccurrences(of: "’", with: "'")
        return phrases.contains { text.contains($0) }
    }

    static let helplineURL = URL(string: "https://findahelpline.com")!

    static var message: String {
        String(localized: "It sounds like you may be carrying something heavy right now, and you deserve to be heard by a real person. If you are in danger, please call your local emergency number. You can find a free, confidential helpline in your country at findahelpline.com, or reach out to someone you trust. Tap here to open it.")
    }
}
