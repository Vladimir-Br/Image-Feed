import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}
    
    private let tokenKey = "OAuth2AccessToken"
    
    var token: String? {
        get {
            return KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let newToken = newValue {
                let isSuccess = KeychainWrapper.standard.set(newToken, forKey: tokenKey)
                if !isSuccess {
                    print("[OAuth2TokenStorage] Ошибка сохранения токена в Keychain")
                }
            } else {
                let isSuccess = KeychainWrapper.standard.removeObject(forKey: tokenKey)
                if !isSuccess {
                    print("[OAuth2TokenStorage] Ошибка удаления токена из Keychain")
                }
            }
        }
    }
    
    func clearToken() {
        self.token = nil
    }
}
