import Foundation
import UIKit

protocol SyncManagerDelegate: AnyObject {
    func syncDidComplete()
    func syncDidFail(error: Error)
}

final class SyncManager {
    
    static let shared = SyncManager()
    
    weak var delegate: SyncManagerDelegate?
    
    private let baseURL = "https://aotd-worker.guitaripod.workers.dev"
    private let syncQueue = DispatchQueue(label: "com.aotd.sync", qos: .background)
    private var isSyncing = false
    
    private init() {
        setupReachability()
    }
    
    private func setupReachability() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(attemptSync),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc func attemptSync() {
        guard !isSyncing else {
            return
        }
        
        guard let userId = UserDefaults.standard.string(forKey: "appleUserId") else {
            return
        }
        
        // Check if user has cloud sync access (Ultimate plan)
        guard let user = DatabaseManager.shared.fetchUser(),
              (user.hasUltimateAccess() || StoreManager.shared.checkEntitlement(.cloudSync)) else {
            print("Sync skipped: User doesn't have cloud sync access")
            return
        }
        
        syncQueue.async { [weak self] in
            self?.performSync(userId: userId)
        }
    }
    
    private func performSync(userId: String) {
        isSyncing = true
        
        do {
            // Get local data that needs syncing
            let user = DatabaseManager.shared.fetchUser()
            let progress = DatabaseManager.shared.fetchProgress(for: user?.id ?? "")
            let achievements = try DatabaseManager.shared.getUserAchievements(userId: user?.id ?? "")
            
            let syncAchievements = achievements.map { SyncUserAchievement(from: $0) }
            
            let syncData = SyncData(
                user: user,
                progress: progress,
                achievements: syncAchievements,
                lastSyncDate: UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
            )
            
            // Send to server
            uploadSyncData(syncData, userId: userId) { [weak self] result in
                switch result {
                case .success(let serverData):
                    self?.mergeServerData(serverData)
                    UserDefaults.standard.set(Date(), forKey: "lastSyncDate")
                    self?.delegate?.syncDidComplete()
                case .failure(let error):
                    self?.delegate?.syncDidFail(error: error)
                }
                self?.isSyncing = false
            }
            
        } catch {
            isSyncing = false
            delegate?.syncDidFail(error: error)
        }
    }
    
    private func uploadSyncData(_ data: SyncData, userId: String, completion: @escaping (Result<SyncData, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/sync") else {
            completion(.failure(SyncError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-Apple-User-Id")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            request.httpBody = jsonData
            
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(SyncError.serverError))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(SyncError.noData))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    // Custom date decoding to handle ISO8601 with fractional seconds
                    let formatter = DateFormatter()
                    formatter.calendar = Calendar(identifier: .iso8601)
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    decoder.dateDecodingStrategy = .custom({ decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)
                        
                        // Try multiple ISO8601 formats
                        let formats = [
                            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",  // With milliseconds
                            "yyyy-MM-dd'T'HH:mm:ssZ",      // Without milliseconds
                            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", // With milliseconds and literal Z
                            "yyyy-MM-dd'T'HH:mm:ss'Z'"      // Without milliseconds and literal Z
                        ]
                        
                        for format in formats {
                            formatter.dateFormat = format
                            if let date = formatter.date(from: dateString) {
                                return date
                            }
                        }
                        
                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Cannot decode date string \(dateString)"
                        )
                    })
                    
                    
                    let serverData = try decoder.decode(SyncData.self, from: data)
                    completion(.success(serverData))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
            
        } catch {
            completion(.failure(error))
        }
    }
    
    private func mergeServerData(_ serverData: SyncData) {
        // Implement conflict resolution strategy
        // For now, we'll use a simple "latest wins" approach based on timestamps
        
        guard let localUser = DatabaseManager.shared.fetchUser(),
              let serverUser = serverData.user else { return }
        
        do {
            // Merge user data - if the server has a different user ID but same Apple ID,
            // update the local user with server data but keep the local ID
            if serverUser.updatedAt > localUser.updatedAt {
                var updatedUser = serverUser
                updatedUser.id = localUser.id  // Keep local user ID
                try DatabaseManager.shared.updateUser(updatedUser)
            }
            
            // Merge progress data
            for serverProgress in serverData.progress {
                if let localProgress = try DatabaseManager.shared.getProgress(
                    userId: localUser.id,
                    beliefSystemId: serverProgress.beliefSystemId,
                    lessonId: serverProgress.lessonId
                ) {
                    // Compare and update if server is newer
                    if serverProgress.updatedAt > localProgress.updatedAt {
                        try DatabaseManager.shared.createOrUpdateProgress(
                            userId: localUser.id,
                            beliefSystemId: serverProgress.beliefSystemId,
                            lessonId: serverProgress.lessonId,
                            status: serverProgress.status,
                            score: serverProgress.score
                        )
                    }
                } else {
                    // New progress from server
                    try DatabaseManager.shared.createOrUpdateProgress(
                        userId: localUser.id,
                        beliefSystemId: serverProgress.beliefSystemId,
                        lessonId: serverProgress.lessonId,
                        status: serverProgress.status,
                        score: serverProgress.score
                    )
                }
            }
            
            // Merge achievements
            for serverAchievement in serverData.achievements {
                try DatabaseManager.shared.unlockAchievement(
                    userId: localUser.id,
                    achievementId: serverAchievement.achievementId,
                    progress: serverAchievement.progress
                )
            }
            
        } catch {
            // Log error for production debugging if needed
        }
    }
}

// MARK: - Models

struct SyncData: Codable {
    let user: User?
    let progress: [Progress]
    let achievements: [SyncUserAchievement]
    let lastSyncDate: Date?
}

// Wrapper to convert UserAchievement for sync
struct SyncUserAchievement: Codable {
    let id: String
    let userId: String
    let achievementId: String
    let progress: Double
    let isCompleted: Bool
    let completedAt: String?
    let createdAt: String
    let updatedAt: String
    
    init(from userAchievement: UserAchievement) {
        self.id = userAchievement.id
        self.userId = userAchievement.userId
        self.achievementId = userAchievement.achievementId
        self.progress = userAchievement.progress
        self.isCompleted = userAchievement.isCompleted
        self.completedAt = userAchievement.isCompleted ? ISO8601DateFormatter().string(from: userAchievement.unlockedAt) : nil
        self.createdAt = ISO8601DateFormatter().string(from: userAchievement.unlockedAt)
        self.updatedAt = ISO8601DateFormatter().string(from: userAchievement.unlockedAt)
    }
}

enum SyncError: LocalizedError {
    case invalidURL
    case serverError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverError:
            return "Server error occurred"
        case .noData:
            return "No data received from server"
        }
    }
}
