import XCTest
import AuthenticationServices
@testable import aotd

class AuthenticationManagerTests: XCTestCase {
    
    var authManager: AuthenticationManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthenticationManager.shared
    }
    
    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.removeObject(forKey: "appleUserFullName")
        UserDefaults.standard.removeObject(forKey: "appleIdentityToken")
        super.tearDown()
    }
    
    func testSignOutClearsUserDefaults() {
        // Arrange
        UserDefaults.standard.set("testUserId", forKey: "appleUserId")
        UserDefaults.standard.set("test@example.com", forKey: "appleUserEmail")
        UserDefaults.standard.set("Test User", forKey: "appleUserFullName")
        UserDefaults.standard.set("testToken", forKey: "appleIdentityToken")
        
        // Act
        authManager.signOut()
        
        // Assert
        XCTAssertNil(UserDefaults.standard.string(forKey: "appleUserId"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "appleUserEmail"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "appleUserFullName"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "appleIdentityToken"))
    }
    
    func testCheckAuthenticationStatusWithNoUserId() {
        // Arrange
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        
        // Act
        let expectation = self.expectation(description: "Auth check")
        var result: Bool?
        
        authManager.checkAuthenticationStatus { isAuthenticated in
            result = isAuthenticated
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertNotNil(result)
            XCTAssertFalse(result!)
        }
    }
}