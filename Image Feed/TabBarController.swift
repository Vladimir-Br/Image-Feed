import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        // Создаем ImagesListViewController из Storyboard
        guard let imagesListViewController = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as? ImagesListViewController else {
            assertionFailure("Не удалось создать ImagesListViewController из Storyboard")
            return
        }
        
        // Создаем презентер с нужными зависимостями
        let imagesListPresenter = ImagesListPresenter(
            imagesListService: ImagesListService.shared
        )
        
        // Конфигурируем ViewController с презентером
        imagesListViewController.configure(imagesListPresenter)
        
        // Настраиваем tabBarItem для ImagesListViewController
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        // Создаем ProfileViewController программно
        let profileViewController = ProfileViewController()
        let profilePresenter = ProfilePresenter(
            profileService: ProfileService.shared,
            profileImageService: ProfileImageService.shared,
            logoutService: ProfileLogoutService.shared
        )
        profileViewController.configure(presenter: profilePresenter)
        
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        viewControllers = [imagesListViewController, profileViewController]
    }
}
