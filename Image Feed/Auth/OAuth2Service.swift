import Foundation

enum AuthServiceError: Error {
    case invalidRequest
    case duplicateRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    private let urlSession = URLSession.shared
    private var currentTask: URLSessionTask?
    private var currentCode: String?
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        if let currentCode = currentCode, currentCode == code, currentTask != nil {
            print("[OAuth2Service] Обнаружен дублирующий запрос с кодом \(code). Игнорируем.")
            completion(.failure(AuthServiceError.duplicateRequest))
            return
        }
        currentTask?.cancel()
        self.currentCode = code
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service]: RequestCreationError - не удалось создать запрос для кода \(code)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            self.currentTask = nil
            switch result {
            case .success(let response):
                self.currentCode = nil
                print("[OAuth2Service] Успешно получен токен.")
                completion(.success(response.accessToken))
            case .failure(let error):
                if (error as NSError).code == NSURLErrorCancelled {
                    print("[OAuth2Service]: RequestCancelled - запрос был отменен")
                } else {
                    print("[OAuth2Service]: NetworkError - \(error.localizedDescription)")
                }
                completion(.failure(error))
            }
        }
        self.currentTask = task
        task.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        print("[OAuth2Service] Создаем URLRequest для кода \(code)")
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service]: URLCreationError - не удалось создать URL для OAuth токена")
            return nil
        }
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = components.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        print("[OAuth2Service] URLRequest успешно создан для URL: \(url)")
        return request
    }
}


