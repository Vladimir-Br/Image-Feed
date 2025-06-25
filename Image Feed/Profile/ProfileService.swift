
import Foundation

// MARK: - Ошибки ProfileService
enum ProfileServiceError: Error {
    case invalidRequest
    case notAuthorized
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?   

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?

    init(from profileResult: ProfileResult) {
        self.username = profileResult.username
        let firstName = profileResult.firstName ?? ""
        let lastName = profileResult.lastName ?? ""
        self.name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        self.loginName = "@\(profileResult.username)"
        self.bio = profileResult.bio
    }
}
final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    private let decoder = JSONDecoder()
    private let session = URLSession.shared
    private var currentTask: URLSessionTask?
    private(set) var profile: Profile?
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Отменяем предыдущий запрос, если он есть
        currentTask?.cancel()
        
        // Создаем URLRequest
        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService] Ошибка: не удалось создать запрос")
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        // Выполняем сетевой запрос
        let task = session.data(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.currentTask = nil
                
                switch result {
                case .success(let data):
                    do {
                        // Декодируем ответ от API
                        let profileResult = try self.decoder.decode(ProfileResult.self, from: data)
                        
                        // Преобразуем в UI модель
                        let profile = Profile(from: profileResult)
                        
                        self.profile = profile
                        
                        print("[ProfileService] Успешно получен профиль для пользователя: \(profile.username)")
                        completion(.success(profile))
                    } catch {
                        print("[ProfileService] Ошибка декодирования: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("[ProfileService] Ошибка сети: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    // MARK: - Private Methods
    private func makeProfileRequest(token: String) -> URLRequest? {
        print("[ProfileService] Создаем URLRequest для получения профиля")
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService] Ошибка: не удалось создать URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("[ProfileService] URLRequest успешно создан для URL: \(url)")
        return request
    }
}
