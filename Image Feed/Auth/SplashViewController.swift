import UIKit

final class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuth"
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
   
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            print("[SplashViewController]: WindowError - неверная конфигурация окна")
            return
        }
       
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
       
        window.rootViewController = tabBarController
        print("[SplashViewController]: NavigationSuccess - переход к главному экрану выполнен")
    }
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self = self else { return }

            switch result {
            case .success(let profile):
                print("[SplashViewController]: ProfileFetchSuccess - профиль успешно загружен для пользователя \(profile.username)")
                
                // Запускаем загрузку URL изображения профиля
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in
                    // Ничего не делаем с результатом - просто запускаем процесс
                }
                
                // Не дожидаемся завершения загрузки изображения - сразу переходим к главному экрану
                self.switchToTabBarController()

            case .failure(let error):
                print("[SplashViewController]: ProfileFetchError - \(error.localizedDescription)")
                // TODO [Sprint 11] Покажите ошибку получения профиля
                break
            }
        }
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers[0] as? AuthViewController
            else {
                assertionFailure("Не удалось подготовить segue для \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            
            viewController.delegate = self
            
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        print("[SplashViewController]: AuthenticationReceived - получена авторизация, начинаем загрузку профиля")
        vc.dismiss(animated: true)
       
        guard let token = storage.token else {
            print("[SplashViewController]: TokenError - токен не найден после авторизации")
            return 
        }
        
        fetchProfile(token: token)
    }
}

