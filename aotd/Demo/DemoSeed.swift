#if DEBUG
import Foundation
import GRDB

/// A deterministic, offline learner profile for screenshots: a seasoned student with purchased
/// paths at every stage of progress, mistakes to review, answered questions, unlocked
/// achievements and books in progress.
enum DemoSeed {
    private struct PathPlan {
        let id: String
        let product: ProductIdentifier?
        let status: Progress.ProgressStatus
        let earnedXP: Int
        let lessonsDone: Int
        let attempts: Int
    }

    private static let plans: [PathPlan] = [
        PathPlan(id: "judaism", product: nil, status: .completed, earnedXP: 700, lessonsDone: 7, attempts: 2),
        PathPlan(id: "egyptian-afterlife", product: .ancientEgyptian, status: .mastered, earnedXP: 700, lessonsDone: 4, attempts: 3),
        PathPlan(id: "aztec-mictlan", product: .aztecMictlan, status: .completed, earnedXP: 700, lessonsDone: 5, attempts: 1),
        PathPlan(id: "greek-underworld", product: .greek, status: .inProgress, earnedXP: 560, lessonsDone: 5, attempts: 1),
        PathPlan(id: "norse", product: .norse, status: .inProgress, earnedXP: 420, lessonsDone: 5, attempts: 1),
        PathPlan(id: "shinto", product: .shinto, status: .inProgress, earnedXP: 350, lessonsDone: 2, attempts: 1),
        PathPlan(id: "buddhism", product: .buddhism, status: .inProgress, earnedXP: 230, lessonsDone: 2, attempts: 1),
        PathPlan(id: "hinduism", product: .hinduism, status: .inProgress, earnedXP: 90, lessonsDone: 1, attempts: 1)
    ]

    private static let mistakePlan: [(path: String, count: Int)] = [("norse", 3), ("greek-underworld", 2), ("buddhism", 2)]

    private static let achievementProgress: [(id: String, progress: Double)] = [
        ("first_step", 1), ("wisdom_seeker", 1), ("quiz_whiz", 1), ("scholar_of_sheol", 1),
        ("journey_through_duat", 1), ("eternal_student", 1), ("cosmic_explorer", 0.72),
        ("perfect_understanding", 0.55), ("afterlife_master", 0.4), ("enlightened_one", 0.25)
    ]

    private static let bookPlan: [(path: String, progress: Double, completed: Bool)] = [
        ("norse", 0.42, false), ("egyptian-afterlife", 1, true), ("greek-underworld", 0.15, false), ("judaism", 0.78, false)
    ]

    static let displayName = "Maren Aldous"
    static let streakDays = 23
    static let userDefaultsToClear = [
        "aotd.review.successCount", "aotd.review.askDates", "aotd.review.successCountAtLastAsk",
        "aotd.review.promptedVersion", "currentBeliefSystemId"
    ]

    /// Wipes every user table and writes the demo profile inside one transaction, so a relaunch
    /// always starts from the same state.
    static func reseed(database: DatabaseManager, beliefSystems: [BeliefSystem]) {
        let byId = Dictionary(uniqueKeysWithValues: beliefSystems.map { ($0.id, $0) })
        do {
            try database.dbQueue.write { db in
                try wipe(db)
                let user = try insertUser(db)
                try insertPurchases(db, userId: user.id)
                try insertProgress(db, userId: user.id, byId: byId)
                try insertAnswers(db, userId: user.id, byId: byId)
                try insertMistakes(db, userId: user.id, byId: byId)
                try insertAchievements(db, userId: user.id)
                try insertConsultations(db, userId: user.id)
            }
        } catch {
            AppLogger.logError(error, context: "Seeding demo world", logger: AppLogger.database)
        }
        applyDefaults()
    }

    /// Reading progress needs the generated books, so it is written after they exist.
    static func seedBookProgress(database: DatabaseManager) {
        guard let user = database.fetchUser() else { return }
        do {
            try database.dbQueue.write { db in
                try BookProgress.filter(Column("userId") == user.id).deleteAll(db)
                for (offset, plan) in bookPlan.enumerated() {
                    guard let book = try Book.fetchOne(db, key: "book_\(plan.path)") else { continue }
                    let chapter = book.chapters[min(book.chapters.count - 1, Int(Double(book.chapters.count) * plan.progress))]
                    let stamp = Date().addingTimeInterval(-Double(offset + 1) * 86_400)
                    let progress = BookProgress(
                        id: UUID().uuidString,
                        userId: user.id,
                        bookId: book.id,
                        currentChapterId: chapter.id,
                        currentPosition: 0,
                        readingProgress: plan.progress,
                        totalReadingTime: 3_600 * plan.progress * 3,
                        lastReadAt: stamp,
                        isCompleted: plan.completed,
                        createdAt: stamp,
                        updatedAt: stamp
                    )
                    try progress.insert(db)
                }
            }
        } catch {
            AppLogger.logError(error, context: "Seeding demo book progress", logger: AppLogger.database)
        }
    }

    private static func wipe(_ db: Database) throws {
        for table in [
            "book_highlights", "book_reading_preferences", "book_progress", "mistake_sessions", "mistakes",
            "oracle_explanation_cache", "oracle_consultations", "purchases", "user_answers",
            "user_achievements", "progress", "users"
        ] {
            if try db.tableExists(table) {
                try db.execute(sql: "DELETE FROM \(table)")
            }
        }
    }

    private static func insertUser(_ db: Database) throws -> User {
        var user = User()
        user.totalXP = plans.reduce(0) { $0 + $1.earnedXP }
        user.currentLevel = max(1, user.totalXP / 100 + 1)
        user.streakDays = streakDays
        user.lastActiveDate = Date()
        try user.insert(db)
        return user
    }

    private static func insertPurchases(_ db: Database, userId: String) throws {
        for (index, plan) in plans.enumerated() {
            guard let product = plan.product else { continue }
            var purchase = Purchase(userId: userId, productId: product.rawValue, transactionId: "demo-\(index)")
            try purchase.insert(db)
        }
    }

    private static func insertProgress(_ db: Database, userId: String, byId: [String: BeliefSystem]) throws {
        for (index, plan) in plans.enumerated() {
            guard let system = byId[plan.id] else { continue }
            let stamp = Date().addingTimeInterval(-Double(index) * 86_400 * 2)
            var path = Progress(userId: userId, beliefSystemId: plan.id)
            path.status = plan.status
            path.earnedXP = plan.earnedXP
            path.totalAttempts = plan.attempts
            path.createdAt = stamp
            path.updatedAt = stamp
            path.completedAt = plan.status == .inProgress ? nil : stamp
            try path.insert(db)
            for lesson in system.lessons.prefix(plan.lessonsDone) {
                var entry = Progress(userId: userId, beliefSystemId: plan.id, lessonId: lesson.id)
                entry.status = .completed
                entry.earnedXP = lesson.xpReward
                entry.score = 80 + (lesson.order * 7) % 21
                entry.completedAt = stamp
                entry.createdAt = stamp
                entry.updatedAt = stamp
                try entry.insert(db)
            }
        }
    }

    private static func insertAnswers(_ db: Database, userId: String, byId: [String: BeliefSystem]) throws {
        var counter = 0
        for plan in plans {
            guard let system = byId[plan.id] else { continue }
            for lesson in system.lessons.prefix(plan.lessonsDone) {
                for question in lesson.questions {
                    counter += 1
                    var answer = UserAnswer(
                        userId: userId,
                        questionId: question.id,
                        userAnswer: "demo",
                        isCorrect: counter % 7 != 0,
                        beliefSystemId: plan.id,
                        lessonId: lesson.id,
                        timeSpent: Double(14 + (counter * 5) % 23)
                    )
                    answer.attemptedAt = Date().addingTimeInterval(-Double(counter) * 3_000)
                    try answer.insert(db)
                }
            }
        }
    }

    private static func insertMistakes(_ db: Database, userId: String, byId: [String: BeliefSystem]) throws {
        for (path, count) in mistakePlan {
            guard let system = byId[path] else { continue }
            let questions = system.lessons.flatMap(\.questions).filter { $0.type == .multipleChoice }
            for question in questions.prefix(count) {
                guard case .string(let correct) = question.correctAnswer.value,
                      let wrong = question.options?.first(where: { $0 != correct }) else { continue }
                var mistake = Mistake(
                    userId: userId,
                    beliefSystemId: path,
                    lessonId: system.lessons.first?.id,
                    questionId: question.id,
                    incorrectAnswer: wrong,
                    correctAnswer: correct
                )
                try mistake.insert(db)
            }
        }
    }

    private static func insertAchievements(_ db: Database, userId: String) throws {
        for entry in achievementProgress {
            var achievement = UserAchievement(userId: userId, achievementId: entry.id, progress: entry.progress)
            try achievement.insert(db)
        }
    }

    private static func insertConsultations(_ db: Database, userId: String) throws {
        for deityId in ["odin", "odin", "anubis", "hecate"] {
            var consultation = OracleConsultation(userId: userId, deityId: deityId)
            try consultation.insert(db)
        }
    }

    private static func applyDefaults() {
        let defaults = UserDefaults.standard
        userDefaultsToClear.forEach { defaults.removeObject(forKey: $0) }
        defaults.set(true, forKey: FirstRunWelcome.completedKey)
        defaults.set(true, forKey: ReminderOffer.shownKey)
        defaults.set(true, forKey: DailyReminder.enabledKey)
        defaults.set(displayName, forKey: "profileDisplayName")
    }
}
#endif
