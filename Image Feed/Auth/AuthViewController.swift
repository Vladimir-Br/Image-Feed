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
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
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
                print("[AuthViewController] Попытка открыть WebView во время авторизации заблокирована")
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
                    print("Authentication successful! Token saved.")
                    vc.dismiss(animated: true) {
                        self.delegate?.didAuthenticate(self)
                    }
                case .failure(let error):
                    print("Authentication error: \(error.localizedDescription)")
                    vc.dismiss(animated: true)
                    // TODO: Показать алерт с ошибкой
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}
    

