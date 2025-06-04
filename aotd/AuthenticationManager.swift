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
        
        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
        }
        
        let userId = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        UserDefaults.standard.set(userId, forKey: "appleUserId")
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
        }
        if let fullName = fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "appleUserFullName")
            }
        }
        UserDefaults.standard.set(idTokenString, forKey: "appleIdentityToken")
        
        DatabaseManager.shared.updateUserAppleId(userId)
        
        delegate?.authenticationDidComplete(userId: userId)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        delegate?.authenticationDidFail(error: error)
    }
}