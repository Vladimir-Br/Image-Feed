import UIKit
import Kingfisher

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {
    private let profileImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "profileImage"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "YP White")
        label.font = .systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "YP Gray")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "YP White")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "logoutButtonImage"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var presenter: ProfilePresenterProtocol?

    func configure(presenter: ProfilePresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUI()
        setupConstraints()
        setupActions()
        presenter?.viewDidLoad()
    }

    func updateProfileDetails(name: String, loginName: String, bio: String?) {
        nameLabel.text = name
        usernameLabel.text = loginName
        infoLabel.text = bio ?? ""
    }

    func updateAvatar(with url: URL?) {
        profileImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"),
            options: [.cacheOriginalImage, .transition(.fade(0.3))]
        ) { result in
            switch result {
            case .success(let value):
                print("[ProfileViewController] Аватар успешно загружен: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("[ProfileViewController] Ошибка загрузки аватара: \(error.localizedDescription)")
            }
        }
    }

    func showLogoutAlert() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
            self?.presenter?.performLogout()
        }
        
        let cancelAction = UIAlertAction(title: "Нет", style: .default)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

    func switchToSplashViewController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("[ProfileViewController] Не удалось получить главное окно")
            return
        }

        let splashViewController = SplashViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft) {
            window.rootViewController = splashViewController
        }
    }

    private func setupBackground() {
        view.backgroundColor = UIColor(named: "YP Black")
    }
    
    private func setupUI() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(usernameLabel)
        view.addSubview(infoLabel)
        view.addSubview(logoutButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            
            infoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            infoLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: logoutButton.trailingAnchor, constant: 16),
            logoutButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
    }

    @objc private func didTapLogoutButton(_ sender: Any) {
        presenter?.didTapLogoutButton()
    }

    deinit {
        print("[ProfileViewController] Деинициализация")
    }
}
