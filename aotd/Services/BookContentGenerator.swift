import Foundation

final class BookContentGenerator {
    
    private let databaseManager: DatabaseManager
    private let contentLoader: ContentLoader
    
    init(databaseManager: DatabaseManager = .shared, contentLoader: ContentLoader = ContentLoader()) {
        self.databaseManager = databaseManager
        self.contentLoader = contentLoader
    }
    
    // MARK: - Public Methods
    
    func generateBook(for beliefSystem: BeliefSystem) throws -> Book {
        AppLogger.content.info("Generating book for belief system", metadata: [
            "beliefSystemId": beliefSystem.id,
            "beliefSystemName": beliefSystem.name
        ])
        
        let chapters = createChapters(from: beliefSystem)
        
        // Validate chapters are in correct order and no duplicates
        var seenChapterNumbers = Set<Int>()
        for chapter in chapters {
            if seenChapterNumbers.contains(chapter.chapterNumber) {
                AppLogger.content.error("Duplicate chapter number found", metadata: [
                    "chapterNumber": chapter.chapterNumber,
                    "chapterTitle": chapter.title
                ])
            }
            seenChapterNumbers.insert(chapter.chapterNumber)
        }
        
        let totalWords = chapters.reduce(0) { $0 + $1.wordCount }
        let estimatedReadingTime = Int(Double(totalWords) / 200.0) // Assuming 200 words per minute
        
        let book = Book(
            id: "book_\(beliefSystem.id)",
            beliefSystemId: beliefSystem.id,
            title: "\(beliefSystem.name): A Complete Guide to the Afterlife",
            author: "App of the Dead",
            coverImageName: nil,
            chapters: chapters,
            totalWords: totalWords,
            estimatedReadingTime: estimatedReadingTime,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return book
    }
    
    func generateAndSaveAllBooks() {
        let beliefSystems = contentLoader.loadBeliefSystems()
        var generatedCount = 0
        
        for beliefSystem in beliefSystems {
            do {
                // Check if book already exists
                if try databaseManager.getBook(by: "book_\(beliefSystem.id)") != nil {
                    AppLogger.content.info("Book already exists, skipping", metadata: [
                        "beliefSystemId": beliefSystem.id
                    ])
                    continue
                }
                
                let book = try generateBook(for: beliefSystem)
                try databaseManager.saveBook(book)
                generatedCount += 1
                
                AppLogger.content.info("Generated and saved book", metadata: [
                    "bookId": book.id,
                    "beliefSystemName": beliefSystem.name,
                    "chapterCount": book.chapters.count,
                    "totalWords": book.totalWords
                ])
            } catch {
                AppLogger.logError(error, context: "Generating book for \(beliefSystem.name)", logger: AppLogger.content)
            }
        }
        
        AppLogger.content.info("Book generation complete", metadata: [
            "totalBeliefSystems": beliefSystems.count,
            "booksGenerated": generatedCount
        ])
    }
    
    // MARK: - Private Methods
    
    private func createChapters(from beliefSystem: BeliefSystem) -> [Chapter] {
        var chapters: [Chapter] = []
        var chapterNumber = 1
        
        // Introduction chapter - FIRST
        chapters.append(createIntroductionChapter(
            for: beliefSystem,
            chapterNumber: chapterNumber
        ))
        chapterNumber += 1
        
        // Overview chapter
        chapters.append(createOverviewChapter(
            for: beliefSystem,
            chapterNumber: chapterNumber
        ))
        chapterNumber += 1
        
        // Create chapters from lessons
        for lesson in beliefSystem.lessons {
            let chapter = createLessonChapter(
                lesson: lesson,
                beliefSystemId: beliefSystem.id,
                chapterNumber: chapterNumber
            )
            chapters.append(chapter)
            chapterNumber += 1
        }
        
        // Key concepts chapter
        chapters.append(createKeyConceptsChapter(
            for: beliefSystem,
            chapterNumber: chapterNumber
        ))
        chapterNumber += 1
        
        // Conclusion chapter - LAST
        chapters.append(createConclusionChapter(
            for: beliefSystem,
            chapterNumber: chapterNumber
        ))
        
        // Ensure chapters are properly ordered
        chapters.sort { $0.chapterNumber < $1.chapterNumber }
        
        // Validate chapter sequence
        for (index, chapter) in chapters.enumerated() {
            if chapter.chapterNumber != index + 1 {
                AppLogger.content.warning("Chapter numbering mismatch", metadata: [
                    "expected": index + 1,
                    "actual": chapter.chapterNumber,
                    "title": chapter.title
                ])
            }
        }
        
        return chapters
    }
    
    private func createIntroductionChapter(for beliefSystem: BeliefSystem, chapterNumber: Int) -> Chapter {
        let content = """
        Welcome to this comprehensive exploration of \(beliefSystem.name) and its understanding of the afterlife. This book provides an in-depth look at one of humanity's most profound questions: what happens after we die?
        
        Throughout history, \(beliefSystem.name) has offered unique insights and teachings about the nature of death, the journey of the soul, and the possibilities that await us beyond this life. Whether you approach this topic from a place of curiosity, academic interest, or personal spiritual exploration, this book aims to present these teachings in a clear and accessible manner.
        
        As you read through these chapters, you'll discover:
        
        • The historical and cultural context of \(beliefSystem.name)'s afterlife beliefs
        • Core concepts and terminology essential to understanding these teachings
        • Detailed explanations of what practitioners believe happens after death
        • The moral and ethical implications of these beliefs
        • How these concepts influence daily life and spiritual practice
        
        This book is structured to guide you from fundamental concepts to more complex ideas, building your understanding progressively. Each chapter focuses on a specific aspect of \(beliefSystem.name)'s afterlife teachings, providing both theoretical knowledge and practical insights.
        
        Remember that these are living beliefs, held sacred by millions of people around the world. We approach them with respect and scholarly interest, seeking to understand rather than to judge or compare.
        
        Let us begin this journey of discovery together, exploring the rich tapestry of beliefs that \(beliefSystem.name) offers about life, death, and what lies beyond.
        """
        
        return Chapter(
            id: "intro_\(beliefSystem.id)",
            bookId: "book_\(beliefSystem.id)",
            chapterNumber: chapterNumber,
            title: "Introduction: Exploring \(beliefSystem.name)'s Vision of the Afterlife",
            content: content,
            wordCount: content.split(separator: " ").count
        )
    }
    
    private func createOverviewChapter(for beliefSystem: BeliefSystem, chapterNumber: Int) -> Chapter {
        let content = """
        \(beliefSystem.description)
        
        Understanding \(beliefSystem.name)'s approach to the afterlife requires us to first grasp its fundamental worldview and core principles. This tradition, which has evolved over centuries, offers a unique perspective on the nature of existence, consciousness, and the journey of the soul.
        
        Historical Context
        
        The origins of \(beliefSystem.name)'s afterlife beliefs can be traced back through various historical periods, each contributing layers of meaning and interpretation. These beliefs have been shaped by cultural exchanges, philosophical developments, and the experiences of countless practitioners throughout history.
        
        Core Principles
        
        At the heart of \(beliefSystem.name)'s understanding of the afterlife are several key principles:
        
        1. The Nature of the Soul: How \(beliefSystem.name) conceptualizes the essence of human consciousness and its relationship to the physical body.
        
        2. The Purpose of Life: The role that earthly existence plays in the greater spiritual journey.
        
        3. Moral and Ethical Frameworks: How actions in this life influence the afterlife experience.
        
        4. The Transition Process: What practitioners believe occurs at the moment of death and immediately after.
        
        5. The Afterlife Realms: The various states or locations where souls may journey after death.
        
        Cultural Significance
        
        These beliefs about the afterlife are not merely abstract concepts but deeply influence how practitioners of \(beliefSystem.name) approach daily life. From rituals surrounding death and mourning to ethical decisions and spiritual practices, the afterlife teachings permeate many aspects of the tradition.
        
        Modern Interpretations
        
        As with all living traditions, \(beliefSystem.name)'s understanding of the afterlife continues to evolve. Contemporary scholars and practitioners engage with these ancient teachings in light of modern knowledge and experience, creating a dynamic dialogue between tradition and innovation.
        
        In the following chapters, we will explore each of these aspects in greater detail, building a comprehensive picture of how \(beliefSystem.name) envisions the journey beyond death.
        """
        
        return Chapter(
            id: "overview_\(beliefSystem.id)",
            bookId: "book_\(beliefSystem.id)",
            chapterNumber: chapterNumber,
            title: "Overview: The Foundation of \(beliefSystem.name)'s Afterlife Beliefs",
            content: content,
            wordCount: content.split(separator: " ").count
        )
    }
    
    private func createLessonChapter(lesson: Lesson, beliefSystemId: String, chapterNumber: Int) -> Chapter {
        var content = lesson.content
        
        // Add context and expansion to the lesson content
        content += "\n\nDeeper Understanding\n\n"
        content += "This aspect of the afterlife teaching reveals important insights about how practitioners view the relationship between this life and the next. "
        
        // Extract and elaborate on key concepts from questions
        if !lesson.questions.isEmpty {
            content += "\n\nKey Points to Remember\n\n"
            
            for (index, question) in lesson.questions.enumerated() {
                if let explanation = generateExplanationFromQuestion(question) {
                    content += "\(index + 1). \(explanation)\n\n"
                }
            }
        }
        
        // Add reflection section
        content += "\n\nReflection\n\n"
        content += "As we consider these teachings, it's worth reflecting on how they might influence one's approach to life, death, and spiritual practice. "
        content += "These concepts offer a framework for understanding not just what happens after death, but how to live meaningfully in the present moment."
        
        return Chapter(
            id: lesson.id,
            bookId: "book_\(beliefSystemId)",
            chapterNumber: chapterNumber,
            title: lesson.title,
            content: content,
            wordCount: content.split(separator: " ").count
        )
    }
    
    private func createKeyConceptsChapter(for beliefSystem: BeliefSystem, chapterNumber: Int) -> Chapter {
        var content = "Throughout our exploration of \(beliefSystem.name)'s afterlife teachings, several key concepts have emerged that deserve special attention. Understanding these terms and ideas is essential for grasping the full picture of this tradition's vision of life after death.\n\n"
        
        // Extract key terms from lessons
        var keyTerms: Set<String> = []
        for lesson in beliefSystem.lessons {
            keyTerms.formUnion(lesson.keyTerms)
        }
        
        content += "Essential Terminology\n\n"
        
        for term in keyTerms.sorted() {
            content += "• \(term): A fundamental concept in understanding \(beliefSystem.name)'s afterlife teachings.\n"
        }
        
        content += "\n\nInterconnected Beliefs\n\n"
        content += "These concepts do not exist in isolation but form an interconnected web of meaning. Each element supports and illuminates the others, creating a comprehensive worldview that addresses questions of mortality, morality, and meaning.\n\n"
        
        content += "The journey through \(beliefSystem.name)'s afterlife teachings reveals a sophisticated understanding of human consciousness and its ultimate destiny. These beliefs offer both comfort and challenge, providing a framework for understanding death while also calling practitioners to live with greater awareness and purpose.\n\n"
        
        content += "Practical Applications\n\n"
        content += "Understanding these key concepts is not merely an intellectual exercise. For practitioners of \(beliefSystem.name), these teachings inform:\n\n"
        content += "• Daily spiritual practices and rituals\n"
        content += "• Ethical decision-making\n"
        content += "• Approaches to grief and loss\n"
        content += "• Preparation for one's own death\n"
        content += "• Understanding of life's purpose and meaning\n\n"
        
        content += "As we move toward the conclusion of our exploration, keep these key concepts in mind. They form the foundation upon which \(beliefSystem.name)'s entire understanding of the afterlife is built."
        
        return Chapter(
            id: "concepts_\(beliefSystem.id)",
            bookId: "book_\(beliefSystem.id)",
            chapterNumber: chapterNumber,
            title: "Key Concepts: Essential Elements of \(beliefSystem.name)'s Afterlife Teachings",
            content: content,
            wordCount: content.split(separator: " ").count
        )
    }
    
    private func createConclusionChapter(for beliefSystem: BeliefSystem, chapterNumber: Int) -> Chapter {
        let content = """
        As we reach the end of our journey through \(beliefSystem.name)'s teachings on the afterlife, it's time to reflect on what we've discovered and consider the broader implications of these beliefs.
        
        A Comprehensive Vision
        
        Throughout this book, we've explored how \(beliefSystem.name) presents a comprehensive vision of what awaits us after death. From the moment of transition to the ultimate destiny of the soul, this tradition offers detailed teachings that address humanity's deepest questions about mortality and meaning.
        
        We've seen how these beliefs are not arbitrary but arise from centuries of philosophical reflection, spiritual experience, and cultural wisdom. They represent one of humanity's great attempts to understand and contextualize the mystery of death.
        
        Universal Themes
        
        While \(beliefSystem.name)'s specific teachings are unique, they touch on universal human concerns:
        
        • The continuity of consciousness beyond physical death
        • The importance of how we live our lives
        • The possibility of growth and transformation after death
        • The ultimate purpose and meaning of existence
        • The relationship between individual souls and the greater cosmos
        
        Living with Awareness
        
        Perhaps most importantly, \(beliefSystem.name)'s afterlife teachings are not meant to be passive beliefs but active influences on how practitioners live. Understanding what may await us after death can inspire us to:
        
        • Live with greater intentionality and purpose
        • Cultivate compassion and wisdom
        • Face our own mortality with less fear
        • Support others through grief and loss
        • Appreciate the preciousness of life
        
        Continuing the Journey
        
        This book has provided an introduction to \(beliefSystem.name)'s rich teachings on the afterlife, but it is only the beginning. For those inspired to learn more, there are many paths forward:
        
        • Deeper study of primary texts and teachings
        • Engagement with practicing communities
        • Personal spiritual practice and reflection
        • Comparative study with other traditions
        • Application of these insights to daily life
        
        Final Reflections
        
        Whether you approach these teachings as a practitioner, a student of religion, or simply someone curious about different perspectives on death and afterlife, we hope this exploration has been illuminating. \(beliefSystem.name)'s vision of the afterlife offers both comfort and challenge, inviting us to consider not just what happens after we die, but how we choose to live.
        
        In the end, these teachings remind us that death is not an ending but a transformation, not a wall but a doorway. How we understand and prepare for that transition can profoundly influence both how we live and how we die.
        
        May this knowledge serve you well on your own journey, wherever it may lead.
        """
        
        return Chapter(
            id: "conclusion_\(beliefSystem.id)",
            bookId: "book_\(beliefSystem.id)",
            chapterNumber: chapterNumber,
            title: "Conclusion: Integrating \(beliefSystem.name)'s Wisdom",
            content: content,
            wordCount: content.split(separator: " ").count
        )
    }
    
    private func generateExplanationFromQuestion(_ question: Question) -> String? {
        switch question.type {
        case .multipleChoice:
            if case .string(let correctAnswer) = question.correctAnswer.value {
                return "\(question.question) The answer is \(correctAnswer), which highlights an important aspect of this tradition's understanding."
            }
        case .trueFalse:
            if case .string(let answer) = question.correctAnswer.value {
                return "\(question.question) This statement is \(answer), revealing a key principle in these teachings."
            }
        case .matching:
            return "Understanding the connections between different concepts helps us see how these teachings form a cohesive worldview."
        }
        return nil
    }
}
