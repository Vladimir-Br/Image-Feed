import Foundation

// Добавляем enum для ошибок ProfileImageService
enum ProfileImageServiceError: Error {
    case invalidRequest
    case notAuthorized
    case invalidData
}
// Эти структуры лучше объявить за пределами класса для лучшей читаемости.
struct UserResult: Codable {
    let profileImage: ProfileImageURL

    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImageURL: Codable {
    let small: String?
}



final class ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    static let shared = ProfileImageService()
    private init() {}
    
    // MARK: - Public Properties
    private(set) var avatarURL: String?
    
    // MARK: - Private Properties
    private var currentTask: URLSessionTask?
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared // Получаем доступ к хранилищу
    private let decoder = JSONDecoder()
    
    // MARK: - Public Methods
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread, "Этот метод должен вызываться из главного потока")

        // Предотвращаем гонку
        currentTask?.cancel()
        
        // Получаем токен
        guard let token = tokenStorage.token else {
            completion(.failure(ProfileImageServiceError.notAuthorized))
            return
        }

        // Создаем запрос
        guard let request = makeProfileImageRequest(username: username, token: token) else {
            completion(.failure(ProfileImageServiceError.invalidRequest))
            return
        }
        
        // Выполняем сетевой запрос
        let task = urlSession.data(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.currentTask = nil
                
                switch result {
                case .success(let data):
                    do {
                        // Декодируем ответ от API
                        let userResult = try self.decoder.decode(UserResult.self, from: data)
                        
                        // Проверяем наличие URL
                        guard let smallImageURL = userResult.profileImage.small else {
                            completion(.failure(ProfileImageServiceError.invalidData))
                            return
                        }
                        
                        self.avatarURL = smallImageURL
                        print("[ProfileImageService] Успешно получен URL аватара: \(smallImageURL)")
                        completion(.success(smallImageURL))
                        
                        // Публикуем уведомление об изменении URL аватара
                        NotificationCenter.default
                            .post(
                                name: ProfileImageService.didChangeNotification,
                                object: self,
                                userInfo: ["URL": smallImageURL]
                            )
                        
                    } catch {
                        print("[ProfileImageService] Ошибка декодирования: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("[ProfileImageService] Ошибка сети: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        self.currentTask = task
        task.resume()
    }
    
    // MARK: - Private Methods
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        print("[ProfileImageService] Создаем URLRequest для получения URL аватара")
        
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileImageService] Ошибка: не удалось создать URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("[ProfileImageService] URLRequest успешно создан для URL: \(url)")
        return request
    }
}
