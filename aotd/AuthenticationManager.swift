import Foundation
import AuthenticationServices
import CryptoKit

protocol AuthenticationManagerDelegate: AnyObject {
    func authenticationDidComplete(userId: String)
    func authenticationDidFail(error: Error)
}

final class AuthenticationManager: NSObject {
    
    static let shared = AuthenticationManager()
    
    weak var delegate: AuthenticationManagerDelegate?
    private var currentNonce: String?
    
    var currentUser: User? {
        return DatabaseManager.shared.fetchUser()
    }
    
    func getCurrentUser() async throws -> User {
        if let user = currentUser {
            return user
        }
        throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
    }
    
    private override init() {
        super.init()
    }
    
    func signInWithApple(presentingViewController: UIViewController) {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = presentingViewController as? ASAuthorizationControllerPresentationContextProviding
        authorizationController.performRequests()
    }
    
    func checkAuthenticationStatus(completion: @escaping (Bool) -> Void) {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        guard let userId = UserDefaults.standard.string(forKey: "appleUserId") else {
            completion(false)
            return
        }
        
        appleIDProvider.getCredentialState(forUserID: userId) { credentialState, error in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    completion(true)
                case .revoked, .notFound:
                    UserDefaults.standard.removeObject(forKey: "appleUserId")
                    UserDefaults.standard.removeObject(forKey: "appleUserEmail")
                    UserDefaults.standard.removeObject(forKey: "appleUserFullName")
                    completion(false)
                default:
                    completion(false)
                }
            }
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.removeObject(forKey: "appleUserFullName")
        UserDefaults.standard.removeObject(forKey: "appleIdentityToken")
        
        DatabaseManager.shared.clearUserSession()
        
        // Logout from RevenueCat
        StoreManager.shared.logout()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }
        
        let userId = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        UserDefaults.standard.set(userId, forKey: "appleUserId")
        
        var userName: String? = nil
        var userEmail: String? = nil
        
        // Try to get previously stored values first
        if let storedEmail = UserDefaults.standard.string(forKey: "appleUserEmail") {
            userEmail = storedEmail
        }
        
        if let storedName = UserDefaults.standard.string(forKey: "appleUserFullName") {
            userName = storedName
        }
        
        // Update with new values if provided
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
            userEmail = email
        }
        if let fullName = fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "appleUserFullName")
                userName = name
            }
        }
        UserDefaults.standard.set(idTokenString, forKey: "appleIdentityToken")
        
        DatabaseManager.shared.updateUserWithAppleData(
            appleId: userId,
            name: userName,
            email: userEmail
        )
        
        // Login to RevenueCat with the Apple user ID
        StoreManager.shared.login(userId: userId)
        
        delegate?.authenticationDidComplete(userId: userId)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        delegate?.authenticationDidFail(error: error)
    }
}
