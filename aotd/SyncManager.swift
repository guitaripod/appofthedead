import Foundation
import UIKit

protocol SyncManagerDelegate: AnyObject {
    func syncDidComplete()
    func syncDidFail(error: Error)
}

final class SyncManager {
    
    static let shared = SyncManager()
    
    weak var delegate: SyncManagerDelegate?
    
    private let baseURL = "https://your-worker.your-subdomain.workers.dev"
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
        guard !isSyncing,
              let userId = UserDefaults.standard.string(forKey: "appleUserId"),
              let token = UserDefaults.standard.string(forKey: "appleIdentityToken") else {
            return
        }
        
        syncQueue.async { [weak self] in
            self?.performSync(userId: userId, token: token)
        }
    }
    
    private func performSync(userId: String, token: String) {
        isSyncing = true
        
        do {
            // Get local data that needs syncing
            let user = DatabaseManager.shared.fetchUser()
            let progress = DatabaseManager.shared.fetchProgress(for: user?.id ?? "")
            let achievements = try DatabaseManager.shared.getUserAchievements(userId: user?.id ?? "")
            
            let syncData = SyncData(
                user: user,
                progress: progress,
                achievements: achievements,
                lastSyncDate: UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
            )
            
            // Send to server
            uploadSyncData(syncData, userId: userId, token: token) { [weak self] result in
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
    
    private func uploadSyncData(_ data: SyncData, userId: String, token: String, completion: @escaping (Result<SyncData, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/sync") else {
            completion(.failure(SyncError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONEncoder().encode(data)
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
                    let serverData = try JSONDecoder().decode(SyncData.self, from: data)
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
            // Merge user data
            if serverUser.updatedAt > localUser.updatedAt {
                try DatabaseManager.shared.updateUser(serverUser)
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
            print("Error merging server data: \(error)")
        }
    }
}

// MARK: - Models

struct SyncData: Codable {
    let user: User?
    let progress: [Progress]
    let achievements: [UserAchievement]
    let lastSyncDate: Date?
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