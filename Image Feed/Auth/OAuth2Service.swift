import Foundation

enum AuthServiceError: Error {
    case invalidRequest
    case duplicateRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    // Выносим URLSession в свойство для лучшей структуры и тестируемости
    private let urlSession = URLSession.shared
    
    // Переменные для управления состоянием запросов
    private var task: URLSessionTask?
    private var lastCode: String?
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Проверяем, что код выполняется в главном потоке
        assert(Thread.isMainThread, "fetchOAuthToken must be called on main thread")
        
        // Если уже выполняется запрос, и код в нем совпадает с текущим - это дубликат.
        // Ничего не делаем, выходим.
        if let lastCode = lastCode, lastCode == code, task != nil {
            print("[OAuth2Service] Duplicate request with code \(code). Ignoring.")
            completion(.failure(AuthServiceError.duplicateRequest))
            return
        }
        
        // Если есть активный запрос, но с другим кодом - он более не актуален.
        // Отменяем его перед тем, как начать новый.
        task?.cancel()
        
        // Запоминаем код, с которым будем делать новый запрос.
        lastCode = code
        
        // Создаем запрос
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service] Failed to create URLRequest")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        // Создаем и запускаем задачу
        let task = urlSession.data(for: request) { [weak self] result in
            guard let self = self else { return }
            
            // Обрабатываем результат в главном потоке
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                        OAuth2TokenStorage.shared.token = response.accessToken
                        completion(.success(response.accessToken))
                    } catch {
                        print("[OAuth2Service] JSON Decoding Error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    // Игнорируем ошибку отмены задачи
                    if (error as NSError).code == NSURLErrorCancelled {
                        print("[OAuth2Service] Request was cancelled.")
                    } else {
                        print("[OAuth2Service] Network Error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
                
                // Очищаем состояние после завершения
                self.task = nil
                self.lastCode = nil
            }
        }
        
        // Сохраняем ссылку на задачу и запускаем
        self.task = task
        task.resume()
        
        print("[OAuth2Service] Started OAuth token request with code \(code)")
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service] Failed to create URLComponents")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else {
            print("[OAuth2Service] Failed to create URL from URLComponents")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return request
    }
}


