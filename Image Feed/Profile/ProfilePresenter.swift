
import Foundation
import UIKit

protocol ProfileViewControllerProtocol: AnyObject {
    func updateProfileDetails(name: String, loginName: String, bio: String?)
    func updateAvatar(with url: URL?)
    func showLogoutAlert()
    func switchToSplashViewController()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
    func performLogout()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol
    private let logoutService: ProfileLogoutServiceProtocol
    private var profileImageServiceObserver: NSObjectProtocol?

    init(
        profileService: ProfileServiceProtocol,
        profileImageService: ProfileImageServiceProtocol,
        logoutService: ProfileLogoutServiceProtocol
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.logoutService = logoutService
    }

    func viewDidLoad() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }

        updateProfileDetails()
        updateAvatar()
    }

    private func updateProfileDetails() {
        guard let profile = profileService.profile else {
            print("[ProfilePresenter] Профиль не найден")
            return
        }
        
        view?.updateProfileDetails(
            name: profile.name,
            loginName: profile.loginName,
            bio: profile.bio
        )
    }

    private func updateAvatar() {
        guard let avatarURL = profileImageService.avatarURL,
              let url = URL(string: avatarURL) else {
            print("[ProfilePresenter] Не удалось получить URL аватара")
            view?.updateAvatar(with: nil)
            return
        }

        view?.updateAvatar(with: url)
    }

    func didTapLogoutButton() {
        view?.showLogoutAlert()
    }

    func performLogout() {
        logoutService.logout()
        view?.switchToSplashViewController()
    }

    deinit {
        print("[ProfilePresenter] Деинициализация")
    }
}
