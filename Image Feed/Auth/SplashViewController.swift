import UIKit

final class SplashViewController: UIViewController {
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    
    // 1. Создаём свойство для логотипа
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "Vector")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupLogo()
    }
    
    private func setupLogo() {
        // 2. Добавляем на вью
        view.addSubview(logoImageView)
        // 3. Центрируем
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 75), // размеры из Storyboard
            logoImageView.heightAnchor.constraint(equalToConstant: 78)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            showAuthController()
        }
    }
    
    private func showAuthController() {
        // 4. Создаём AuthViewController программно
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: "AuthNavigationController") as? UINavigationController,
              let viewController = navigationController.viewControllers.first as? AuthViewController else {
            assertionFailure("Не удалось создать AuthViewController из Storyboard")
            return
        }
        viewController.delegate = self
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
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
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
            case .failure(let error):
                print("[SplashViewController]: ProfileFetchError - \(error.localizedDescription)")
                // TODO: Покажите ошибку получения профиля
                break
            }
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

