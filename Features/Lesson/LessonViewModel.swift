import UIKit
import MidgarCore
import AppOfTheDeadCore

protocol LessonViewModelDelegate: AnyObject {
    func lessonViewModelDidRequestQuiz(_ viewModel: LessonViewModel, questions: [Question])
    func lessonViewModelDidRequestExit(_ viewModel: LessonViewModel)
}

final class LessonViewModel {
    
    weak var delegate: LessonViewModelDelegate?
    
    private let lesson: Lesson
    private let beliefSystem: BeliefSystem
    private let currentLessonIndex: Int
    private let totalLessons: Int
    
    var lessonTitle: String {
        lesson.title
    }
    
    var lessonContent: String {
        lesson.content
    }
    
    var keyTerms: [String] {
        lesson.keyTerms
    }
    
    var progress: Float {
        Float(currentLessonIndex) / Float(totalLessons)
    }
    
    var beliefSystemColor: UIColor? {
        PapyrusDesignSystem.Colors.tradition(beliefSystem.color)
    }
    
    var beliefSystemId: String {
        beliefSystem.id
    }

    var beliefSystemName: String {
        beliefSystem.name
    }

    /// "Lesson 2 of 8", for the eyebrow over the first card.
    var lessonPosition: String {
        String(localized: "Lesson \(currentLessonIndex + 1) of \(totalLessons)")
    }

    /// The lesson's text in short cards of a few sentences, read one at a time.
    lazy var cards: [String] = Self.cards(from: lesson.content)

    /// Groups whole sentences into cards of about `targetLength` characters; a sentence longer than that gets a card
    /// of its own.
    static func cards(from content: String, targetLength: Int = 280) -> [String] {
        var sentences: [String] = []
        content.enumerateSubstrings(in: content.startIndex..., options: .bySentences) { substring, _, _, _ in
            let sentence = (substring ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty { sentences.append(sentence) }
        }
        var cards: [String] = []
        var current = ""
        for sentence in sentences {
            if current.isEmpty {
                current = sentence
            } else if current.count + sentence.count + 1 <= targetLength {
                current += " " + sentence
            } else {
                cards.append(current)
                current = sentence
            }
        }
        if !current.isEmpty { cards.append(current) }
        return cards.isEmpty ? [content] : cards
    }
    
    init(lesson: Lesson, beliefSystem: BeliefSystem, currentLessonIndex: Int, totalLessons: Int) {
        self.lesson = lesson
        self.beliefSystem = beliefSystem
        self.currentLessonIndex = currentLessonIndex
        self.totalLessons = totalLessons
    }
    
    func continueToQuiz() {
        delegate?.lessonViewModelDidRequestQuiz(self, questions: lesson.questions)
    }
    
    func exitLearningPath() {
        MidgarLog.debug("LessonViewModel - exitLearningPath called", metadata: ["delegateExists": delegate != nil], category: .viewModel)
        delegate?.lessonViewModelDidRequestExit(self)
        MidgarLog.debug("LessonViewModel - Called delegate.lessonViewModelDidRequestExit", category: .viewModel)
    }
}

