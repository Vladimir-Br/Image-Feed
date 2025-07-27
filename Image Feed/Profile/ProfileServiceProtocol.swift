
import Foundation
import UIKit

protocol ProfileServiceProtocol {
    var profile: Profile? { get }
}

protocol ProfileImageServiceProtocol {
    var avatarURL: String? { get }
    static var didChangeNotification: Notification.Name { get }
}

protocol ProfileLogoutServiceProtocol {
    func logout()
}

extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}
extension ProfileLogoutService: ProfileLogoutServiceProtocol {}
