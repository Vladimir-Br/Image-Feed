import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    private let session = URLSession.shared
    private var currentTask: URLSessionTask?
    private(set) var profile: Profile?
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        currentTask?.cancel()
        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService]: RequestCreationError - не удалось создать запрос для токена")
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        let task = session.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self = self else { return }
            self.currentTask = nil
            switch result {
            case .success(let profileResult):
                let profile = Profile(from: profileResult)
                self.profile = profile
                print("[ProfileService] Успешно получен профиль для пользователя: \(profile.username)")
                completion(.success(profile))
            case .failure(let error):
                print("[ProfileService]: NetworkError - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        currentTask = task
        task.resume()
    }
    
    func clearProfile() {
        profile = nil
        currentTask?.cancel()
        currentTask = nil
    }
    
    private func makeProfileRequest(token: String) -> URLRequest? {
        print("[ProfileService] Создаем URLRequest для получения профиля")
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService]: URLCreationError - не удалось создать URL для профиля")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("[ProfileService] URLRequest успешно создан для URL: \(url)")
        return request
    }
}
