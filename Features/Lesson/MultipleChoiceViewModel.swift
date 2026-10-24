import Foundation

final class MultipleChoiceViewModel: BaseQuestionViewModel {
    
    var options: [String] {
        question.options ?? []
    }
}