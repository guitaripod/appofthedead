import UIKit

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
        UIColor(hex: beliefSystem.color)
    }
    
    var beliefSystemId: String {
        beliefSystem.id
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
        print("DEBUG: LessonViewModel - exitLearningPath called, delegate: \(delegate != nil ? "exists" : "nil")")
        delegate?.lessonViewModelDidRequestExit(self)
        print("DEBUG: LessonViewModel - Called delegate.lessonViewModelDidRequestExit")
    }
}

