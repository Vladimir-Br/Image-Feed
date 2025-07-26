
import Foundation
import WebKit

final class ProfileLogoutService {
   static let shared = ProfileLogoutService()
   private init() { }

   func logout() {
      cleanCookies()
      OAuth2TokenStorage.shared.clearToken()
      ProfileService.shared.clearProfile()
      ProfileImageService.shared.clearProfileImage()
      ImagesListService.shared.clearImagesList()
   }

   private func cleanCookies() {
      HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
      WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
         records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
         }
      }
   }
}
