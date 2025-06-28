import UIKit
import ProgressHUD

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    weak var delegate: AuthViewControllerDelegate?
    
    private var isAuthenticating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure("Не удалось подготовить segue для \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == showWebViewSegueIdentifier {
            if isAuthenticating {
                print("[AuthViewController]: SegueBlocked - попытка открыть WebView во время авторизации заблокирована")
                return false
            }
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "YP Black")
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        isAuthenticating = true
        
        UIBlockingProgressHUD.show()
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                UIBlockingProgressHUD.dismiss()
                switch result {
                case .success(let accessToken):
                    OAuth2TokenStorage.shared.token = accessToken
                    print("[AuthViewController]: AuthenticationSuccess - токен успешно сохранен")
                    vc.dismiss(animated: true) {
                        self.delegate?.didAuthenticate(self)
                    }
                case .failure(let error):
                    print("[AuthViewController]: AuthenticationError - \(error.localizedDescription)")
                    let alert = UIAlertController(
                        title: "Что-то пошло не так",
                        message: "Не удалось войти в систему",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { _ in
                        vc.dismiss(animated: true)
                    }))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}
    

