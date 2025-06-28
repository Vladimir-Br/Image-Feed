import Foundation

enum AuthServiceError: Error {
    case invalidRequest
    case duplicateRequest
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    // MARK: - Private Properties
    
    private let urlSession = URLSession.shared
    private var currentTask: URLSessionTask?
    private var currentCode: String?
    
    // MARK: - Public Methods
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 1. Убеждаемся, что начинаем из главного потока.
        assert(Thread.isMainThread, "Этот метод должен вызываться из главного потока")
        
        // 2. Проверяем гонку условий: если уже есть активный запрос с таким же кодом, выходим.
        if let currentCode = currentCode, currentCode == code, currentTask != nil {
            print("[OAuth2Service] Обнаружен дублирующий запрос с кодом \(code). Игнорируем.")
            completion(.failure(AuthServiceError.duplicateRequest))
            return
        }
        
        // 3. Если есть активный, но устаревший запрос (с другим кодом) — отменяем его.
        currentTask?.cancel()
        
        // 4. Запоминаем новый код, с которым будем работать.
        self.currentCode = code
        
        // 5. Создаем запрос.
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service]: RequestCreationError - не удалось создать запрос для кода \(code)")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        // 6. Создаем сетевую задачу. URLSession сам выполнит ее в фоновом потоке.
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            
            // 8. Очищаем состояние задачи сразу при получении любого результата.
            self.currentTask = nil
            
            // 9. Обрабатываем результат.
            switch result {
            case .success(let response):
                // 10. Очищаем код только после успешного получения токена.
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
        
        // 10. Сохраняем ссылку на новую задачу и запускаем ее.
        self.currentTask = task
        task.resume()
    }
    
    // MARK: - Private Methods
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        // Базовый URL без параметров
        print("[OAuth2Service] Создаем URLRequest для кода \(code)")
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service]: URLCreationError - не удалось создать URL для OAuth токена")
            return nil
        }
        
        // Компоненты для тела запроса
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
        // Кодируем параметры и помещаем их в тело запроса
        request.httpBody = components.query?.data(using: .utf8)
        // Устанавливаем заголовок, чтобы сервер знал, как парсить тело
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        print("[OAuth2Service] URLRequest успешно создан для URL: \(url)")
        return request
    }
}


