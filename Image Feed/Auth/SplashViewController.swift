import UIKit

final class SplashViewController: UIViewController {
    // MARK: - Properties
    
    // Идентификатор сегвея к экрану авторизации
    private let showAuthenticationScreenSegueIdentifier = "ShowAuth"
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Настраиваем внешний вид экрана
        view.backgroundColor = UIColor(named: "YP Black")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Проверяем наличие токена авторизации
        if let _ = OAuth2TokenStorage.shared.token {
            // Если токен есть, переходим к основному экрану
            switchToTabBarController()
        } else {
            // Если токена нет, переходим к экрану авторизации
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
    
    // MARK: - Navigation
    
    // Метод для перехода к основному экрану приложения
    private func switchToTabBarController() {
        // Получаем экземпляр window приложения
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        // Создаём экземпляр TabBarController из Storyboard
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        // Устанавливаем TabBarController как rootViewController
        window.rootViewController = tabBarController
    }
}

// MARK: - Navigation
extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Проверим, что переходим на авторизацию
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            
            // Доберёмся до первого контроллера в навигации
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers[0] as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            
            // Установим делегатом контроллера наш SplashViewController
            viewController.delegate = self
            
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        // Закрываем экран авторизации
        vc.dismiss(animated: true)
        // Переходим к основному экрану
        switchToTabBarController()
    }
}

