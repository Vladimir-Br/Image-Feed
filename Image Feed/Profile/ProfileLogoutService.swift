
import Foundation
import WebKit

final class ProfileLogoutService {
   static let shared = ProfileLogoutService()
   private init() { }

   func logout() {
      // 1. Очищаем куки
      cleanCookies()
      
      // 2. Очищаем токен из UserDefaults (или Keychain)
      OAuth2TokenStorage.shared.clearToken() // Предполагаем, что создадим такой метод
      
      // 3. Сбрасываем данные сервисов
      // ProfileService должен "забыть" загруженный профиль
      ProfileService.shared.clearProfile()
      
      // ProfileImageService должен "забыть" URL аватарки
      ProfileImageService.shared.clearProfileImage()
      
      // ImagesListService должен "забыть" ленту фотографий
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
