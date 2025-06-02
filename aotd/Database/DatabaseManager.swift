import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue!
    private let contentLoader = ContentLoader()
    
    private init() {
        setupDatabase()
    }
    
    init(inMemory: Bool) {
        if inMemory {
            setupInMemoryDatabase()
        } else {
            setupDatabase()
        }
    }
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let databaseURL = appSupportURL.appendingPathComponent("aotd.sqlite")
            
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            
            try dbQueue.write { db in
                try User.createTable(db)
                try Progress.createTable(db)
                try UserAchievement.createTable(db)
                try UserAnswer.createTable(db)
            }
            
        } catch {
            fatalError("Database setup failed: \(error)")
        }
    }
    
    private func setupInMemoryDatabase() {
        do {
            dbQueue = try DatabaseQueue()
            
            try dbQueue.write { db in
                try User.createTable(db)
                try Progress.createTable(db)
                try UserAchievement.createTable(db)
                try UserAnswer.createTable(db)
            }
            
        } catch {
            fatalError("In-memory database setup failed: \(error)")
        }
    }
    
    // MARK: - User Management
    
    func createUser(name: String, email: String) throws -> User {
        var user = User(name: name, email: email)
        try dbQueue.write { db in
            try user.insert(db)
        }
        return user
    }
    
    func getUser(by id: String) throws -> User? {
        return try dbQueue.read { db in
            try User.fetchOne(db, key: id)
        }
    }
    
    func getUserByEmail(_ email: String) throws -> User? {
        return try dbQueue.read { db in
            try User.filter(Column("email") == email).fetchOne(db)
        }
    }
    
    func updateUser(_ user: User) throws {
        var updatedUser = user
        updatedUser.updatedAt = Date()
        try dbQueue.write { db in
            try updatedUser.update(db)
        }
    }
    
    func addXPToUser(userId: String, xp: Int) throws {
        try dbQueue.write { db in
            if var user = try User.fetchOne(db, key: userId) {
                user.addXP(xp)
                try user.update(db)
            }
        }
    }
    
    func deleteUser(_ userId: String) throws {
        try dbQueue.write { db in
            // Delete user's related data first
            try UserAnswer.filter(Column("userId") == userId).deleteAll(db)
            try UserAchievement.filter(Column("userId") == userId).deleteAll(db)
            try Progress.filter(Column("userId") == userId).deleteAll(db)
            
            // Delete the user
            try User.deleteOne(db, key: userId)
        }
    }
    
    // MARK: - Progress Management
    
    func getProgress(userId: String, beliefSystemId: String, lessonId: String? = nil) throws -> Progress? {
        return try dbQueue.read { db in
            var query = Progress.filter(Column("userId") == userId && Column("beliefSystemId") == beliefSystemId)
            if let lessonId = lessonId {
                query = query.filter(Column("lessonId") == lessonId)
            } else {
                query = query.filter(Column("lessonId") == nil)
            }
            return try query.fetchOne(db)
        }
    }
    
    func createOrUpdateProgress(userId: String, beliefSystemId: String, lessonId: String? = nil, 
                               status: Progress.ProgressStatus, score: Int? = nil) throws {
        try dbQueue.write { db in
            // Query progress directly within the write transaction
            var query = Progress.filter(Column("userId") == userId && Column("beliefSystemId") == beliefSystemId)
            if let lessonId = lessonId {
                query = query.filter(Column("lessonId") == lessonId)
            } else {
                query = query.filter(Column("lessonId") == nil)
            }
            
            if var progress = try query.fetchOne(db) {
                progress.status = status
                if let score = score {
                    progress.score = score
                }
                if status == .completed {
                    progress.markCompleted(score: score)
                }
                try progress.update(db)
            } else {
                var newProgress = Progress(userId: userId, beliefSystemId: beliefSystemId, lessonId: lessonId)
                newProgress.status = status
                if let score = score {
                    newProgress.score = score
                }
                if status == .completed {
                    newProgress.markCompleted(score: score)
                }
                try newProgress.insert(db)
            }
        }
    }
    
    func getUserProgress(userId: String) throws -> [Progress] {
        return try dbQueue.read { db in
            try Progress.filter(Column("userId") == userId).fetchAll(db)
        }
    }
    
    // MARK: - Answer Management
    
    func saveUserAnswer(_ answer: UserAnswer) throws {
        var mutableAnswer = answer
        try dbQueue.write { db in
            try mutableAnswer.insert(db)
        }
    }
    
    func getUserAnswers(userId: String, questionId: String? = nil) throws -> [UserAnswer] {
        return try dbQueue.read { db in
            var query = UserAnswer.filter(Column("userId") == userId)
            if let questionId = questionId {
                query = query.filter(Column("questionId") == questionId)
            }
            return try query.order(Column("attemptedAt").desc).fetchAll(db)
        }
    }
    
    func getCorrectAnswersCount(userId: String) throws -> Int {
        return try dbQueue.read { db in
            try UserAnswer.filter(Column("userId") == userId && Column("isCorrect") == true).fetchCount(db)
        }
    }
    
    // MARK: - Achievement Management
    
    func unlockAchievement(userId: String, achievementId: String, progress: Double = 1.0) throws {
        try dbQueue.write { db in
            if var userAchievement = try UserAchievement
                .filter(Column("userId") == userId && Column("achievementId") == achievementId)
                .fetchOne(db) {
                userAchievement.updateProgress(progress)
                try userAchievement.update(db)
            } else {
                var newAchievement = UserAchievement(userId: userId, achievementId: achievementId, progress: progress)
                try newAchievement.insert(db)
            }
        }
    }
    
    func getUserAchievements(userId: String) throws -> [UserAchievement] {
        return try dbQueue.read { db in
            try UserAchievement.filter(Column("userId") == userId).fetchAll(db)
        }
    }
    
    func updateAchievementProgress(userId: String, achievementId: String, progress: Double) throws {
        try dbQueue.write { db in
            if var userAchievement = try UserAchievement
                .filter(Column("userId") == userId && Column("achievementId") == achievementId)
                .fetchOne(db) {
                userAchievement.updateProgress(progress)
                try userAchievement.update(db)
            }
        }
    }
    
    // MARK: - Content Loading
    
    func loadBeliefSystems() -> [BeliefSystem] {
        return contentLoader.loadBeliefSystems()
    }
    
    func loadAchievements() -> [Achievement] {
        return contentLoader.loadAchievements()
    }
    
    func getBeliefSystem(by id: String) -> BeliefSystem? {
        return loadBeliefSystems().first { $0.id == id }
    }
    
    // MARK: - Statistics
    
    func getUserStatistics(userId: String) throws -> UserStatistics {
        return try dbQueue.read { db in
            let user = try User.fetchOne(db, key: userId) ?? User(name: "", email: "")
            let totalProgress = try Progress.filter(Column("userId") == userId).fetchCount(db)
            let completedProgress = try Progress.filter(Column("userId") == userId && Column("status") == Progress.ProgressStatus.completed.rawValue).fetchCount(db)
            let achievements = try UserAchievement.filter(Column("userId") == userId && Column("isCompleted") == true).fetchCount(db)
            let correctAnswers = try UserAnswer.filter(Column("userId") == userId && Column("isCorrect") == true).fetchCount(db)
            
            return UserStatistics(
                totalXP: user.totalXP,
                currentLevel: user.currentLevel,
                totalLessonsStarted: totalProgress,
                totalLessonsCompleted: completedProgress,
                totalAchievements: achievements,
                correctAnswers: correctAnswers
            )
        }
    }
}

struct UserStatistics {
    let totalXP: Int
    let currentLevel: Int
    let totalLessonsStarted: Int
    let totalLessonsCompleted: Int
    let totalAchievements: Int
    let correctAnswers: Int
}