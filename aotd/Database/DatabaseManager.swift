import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue!
    private var contentLoader: ContentLoader?
    
    var database: Database? {
        try? dbQueue.read { $0 }
    }
    
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
                try Purchase.createTable(db)
                try OracleConsultation.createTable(db)
                
                // Run migrations
                try runMigrations(db)
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
                try Purchase.createTable(db)
                try OracleConsultation.createTable(db)
                
                // Run migrations
                try runMigrations(db)
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
    
    func getUserByAppleId(_ appleId: String) throws -> User? {
        return try dbQueue.read { db in
            try User.filter(Column("appleId") == appleId).fetchOne(db)
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
                // Check for active XP boost
                let hasBoost = try Purchase
                    .filter(Column("userId") == userId)
                    .filter(Column("productId") == ProductIdentifier.xpBoost7Days.rawValue)
                    .filter(Column("isActive") == true)
                    .filter(Column("expirationDate") > Date())
                    .fetchOne(db) != nil
                
                let multiplier = hasBoost ? 2 : 1
                let finalXP = xp * multiplier
                user.addXP(finalXP)
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
            try Purchase.filter(Column("userId") == userId).deleteAll(db)
            try OracleConsultation.filter(Column("userId") == userId).deleteAll(db)
            
            // Delete the user
            try User.deleteOne(db, key: userId)
        }
    }
    
    func fetchUser() -> User? {
        do {
            // First try to read existing user
            if let existingUser = try dbQueue.read({ db in
                try User.fetchOne(db)
            }) {
                return existingUser
            }
            
            // If no user exists, create one
            var newUser = User(name: "Learner", email: "learner@aotd.com")
            try dbQueue.write { db in
                try newUser.insert(db)
            }
            return newUser
        } catch {
            return nil
        }
    }
    
    func updateUserAppleId(_ appleId: String) {
        do {
            try dbQueue.write { db in
                if var user = try User.fetchOne(db) {
                    user.appleId = appleId
                    user.updatedAt = Date()
                    try user.update(db)
                }
            }
        } catch {
            AppLogger.logError(error, context: "Update user Apple ID", logger: AppLogger.auth)
        }
    }
    
    func updateUserWithAppleData(appleId: String, name: String? = nil, email: String? = nil) {
        do {
            try dbQueue.write { db in
                if var user = try User.fetchOne(db) {
                    user.appleId = appleId
                    if let name = name, !name.isEmpty {
                        user.name = name
                    }
                    if let email = email, !email.isEmpty {
                        user.email = email
                    }
                    user.updatedAt = Date()
                    try user.update(db)
                }
            }
        } catch {
            AppLogger.logError(error, context: "Update user with Apple data", logger: AppLogger.auth, additionalInfo: ["appleId": appleId])
        }
    }
    
    func clearUserSession() {
        do {
            try dbQueue.write { db in
                if var user = try User.fetchOne(db) {
                    user.appleId = nil
                    user.updatedAt = Date()
                    try user.update(db)
                }
            }
        } catch {
            AppLogger.logError(error, context: "Clear user session", logger: AppLogger.auth)
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
    
    func fetchProgress(for userId: String) -> [Progress] {
        do {
            return try getUserProgress(userId: userId)
        } catch {
            return []
        }
    }
    
    func addXPToProgress(userId: String, beliefSystemId: String, xp: Int) throws {
        try dbQueue.write { db in
            // Get or create progress for belief system
            if var existingProgress = try Progress
                .filter(Column("userId") == userId && Column("beliefSystemId") == beliefSystemId && Column("lessonId") == nil)
                .fetchOne(db) {
                // Update existing progress
                let oldXP = existingProgress.earnedXP
                existingProgress.addXP(xp)
                try existingProgress.update(db)
                AppLogger.database.info("Updated progress for belief system", metadata: [
                    "beliefSystemId": beliefSystemId,
                    "previousXP": oldXP,
                    "currentXP": existingProgress.earnedXP,
                    "xpAdded": xp
                ])
            } else {
                // Create new progress
                var newProgress = Progress(userId: userId, beliefSystemId: beliefSystemId)
                newProgress.addXP(xp)
                try newProgress.insert(db)
                AppLogger.database.info("Created new progress for belief system", metadata: [
                    "beliefSystemId": beliefSystemId,
                    "earnedXP": newProgress.earnedXP
                ])
            }
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
    
    func setContentLoader(_ loader: ContentLoader) {
        self.contentLoader = loader
    }
    
    func loadBeliefSystems() -> [BeliefSystem] {
        guard let contentLoader = contentLoader else {
            AppLogger.content.warning("ContentLoader not set in DatabaseManager")
            return []
        }
        return contentLoader.loadBeliefSystems()
    }
    
    func loadAchievements() -> [Achievement] {
        guard let contentLoader = contentLoader else {
            AppLogger.content.warning("ContentLoader not set in DatabaseManager")
            return []
        }
        return contentLoader.loadAchievements()
    }
    
    // MARK: - Database Migrations
    
    private func runMigrations(_ db: Database) throws {
        // Add earnedXP column to progress table if it doesn't exist
        let progressColumns = try db.columns(in: "progress")
        if !progressColumns.contains(where: { $0.name == "earnedXP" }) {
            try db.alter(table: "progress") { t in
                t.add(column: "earnedXP", .integer).notNull().defaults(to: 0)
            }
            
            // Migrate existing data: calculate earnedXP from user's totalXP for each belief system
            // This is a simple migration that sets initial values
            try db.execute(sql: """
                UPDATE progress 
                SET earnedXP = 0 
                WHERE earnedXP IS NULL
            """)
        }
        
        // Add appleId column to users table if it doesn't exist
        let userColumns = try db.columns(in: "users")
        if !userColumns.contains(where: { $0.name == "appleId" }) {
            try db.alter(table: "users") { t in
                t.add(column: "appleId", .text).unique()
            }
        }
    }
    
    func getBeliefSystem(by id: String) -> BeliefSystem? {
        return loadBeliefSystems().first { $0.id == id }
    }
    
    // MARK: - Oracle Consultation Management
    
    func saveOracleConsultation(_ consultation: OracleConsultation) throws {
        var mutableConsultation = consultation
        try dbQueue.write { db in
            try mutableConsultation.insert(db)
        }
    }
    
    // MARK: - Purchase Management
    
    func hasAccess(userId: String, to productId: ProductIdentifier) -> Bool {
        do {
            return try dbQueue.read { db in
                let purchase = try Purchase
                    .filter(Column("userId") == userId)
                    .filter(Column("productId") == productId.rawValue)
                    .filter(Column("isActive") == true)
                    .fetchOne(db)
                
                return purchase != nil
            }
        } catch {
            AppLogger.logError(error, context: "Checking purchase access", logger: AppLogger.purchases, additionalInfo: ["userId": userId, "productId": productId.rawValue])
            return false
        }
    }
    
    func hasActiveXPBoost(userId: String) -> Bool {
        do {
            return try dbQueue.read { db in
                let purchase = try Purchase
                    .filter(Column("userId") == userId)
                    .filter(Column("productId") == ProductIdentifier.xpBoost7Days.rawValue)
                    .filter(Column("isActive") == true)
                    .filter(Column("expirationDate") > Date())
                    .fetchOne(db)
                
                return purchase != nil
            }
        } catch {
            AppLogger.logError(error, context: "Checking XP boost", logger: AppLogger.purchases, additionalInfo: ["userId": userId])
            return false
        }
    }
    
    func getOracleConsultationCount(userId: String, deityId: String) -> Int {
        do {
            return try dbQueue.read { db in
                try OracleConsultation.getConsultationCount(for: userId, deityId: deityId, in: db)
            }
        } catch {
            AppLogger.logError(error, context: "Getting oracle consultation count", logger: AppLogger.database, additionalInfo: ["userId": userId, "deityId": deityId])
            return 0
        }
    }
    
    func canConsultOracleForFree(userId: String, deityId: String) -> Bool {
        do {
            return try dbQueue.read { db in
                try OracleConsultation.canConsultForFree(userId: userId, deityId: deityId, in: db)
            }
        } catch {
            AppLogger.logError(error, context: "Checking oracle consultation availability", logger: AppLogger.database, additionalInfo: ["userId": userId, "deityId": deityId])
            return false
        }
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