import Foundation

final class ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    static let shared = ProfileImageService()
    private init() {}
    
    private(set) var avatarURL: String?
    
    private var currentTask: URLSessionTask?
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        currentTask?.cancel()
        guard let token = tokenStorage.token else {
            completion(.failure(ProfileImageServiceError.notAuthorized))
            return
        }
        
        guard let request = makeProfileImageRequest(username: username, token: token) else {
            print("[ProfileImageService]: RequestCreationError - не удалось создать запрос для пользователя \(username)")
            completion(.failure(ProfileImageServiceError.invalidRequest))
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self = self else { return }
            self.currentTask = nil
            switch result {
            case .success(let userResult):
                guard let smallImageURL = userResult.profileImage.small else {
                    completion(.failure(ProfileImageServiceError.invalidData))
                    return
                }
                
                self.avatarURL = smallImageURL
                print("[ProfileImageService] Успешно получен URL аватара: \(smallImageURL)")
                completion(.success(smallImageURL))
                NotificationCenter.default
                    .post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": smallImageURL]
                    )
                
            case .failure(let error):
                print("[ProfileImageService]: NetworkError - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        self.currentTask = task
        task.resume()
    }
    
    func clearProfileImage() {
        avatarURL = nil
        currentTask?.cancel()
        currentTask = nil
        print("[ProfileImageService] Состояние очищено.")
    }
    
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        print("[ProfileImageService] Создаем URLRequest для получения URL аватара")
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileImageService]: URLCreationError - не удалось создать URL для пользователя \(username)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("[ProfileImageService] URLRequest успешно создан для URL: \(url)")
        return request
    }
}
