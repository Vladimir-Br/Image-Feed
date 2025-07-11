
import Foundation

struct PhotoResult: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let width: Int
    let height: Int
    let color: String
    let blurHash: String?
    let likes: Int
    let likedByUser: Bool
    let description: String?
    let urls: UrlsResult
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case width
        case height
        case color
        case blurHash = "blur_hash"
        case likes
        case likedByUser = "liked_by_user"
        case description
        case urls
    }
}

struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

// MARK: - Network Errors
// enum NetworkError удалён, используем общий из Models/NetworkError.swift

final class ImagesListService {
    // MARK: - Notifications
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    // MARK: - Properties
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var isLoading: Bool = false
    
    // MARK: - Networking
    func fetchPhotosNextPage() {
        // Если уже идёт загрузка — выходим
        if isLoading { return }
        isLoading = true
        
        // Определяем номер следующей страницы
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        // Создаём запрос
        guard let request = makeRequest(page: nextPage) else {
            isLoading = false
            return
        }
        
        // Выполняем сетевой запрос
        performRequest(request) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let photoResults):
                    let newPhotos = self.convertToPhotos(photoResults)
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    
                case .failure(let error):
                    print("Ошибка загрузки фотографий: \(error)")
                }
                
                self.isLoading = false
                NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
            }
        }
    }
    
    // MARK: - Private Methods
    private func makeRequest(page: Int) -> URLRequest? {
        var urlComponents = URLComponents(string: "https://api.unsplash.com/photos")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    private func performRequest(_ request: URLRequest, completion: @escaping (Result<[PhotoResult], Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
        
            do {
                let photoResults = try JSONDecoder().decode([PhotoResult].self, from: data)
                completion(.success(photoResults))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func convertToPhotos(_ photoResults: [PhotoResult]) -> [Photo] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        return photoResults.map { photoResult in
            Photo(
                id: photoResult.id,
                size: CGSize(width: photoResult.width, height: photoResult.height),
                createdAt: dateFormatter.date(from: photoResult.createdAt),
                welcomeDescription: photoResult.description,
                thumbImageURL: photoResult.urls.thumb,
                largeImageURL: photoResult.urls.full,
                isLiked: photoResult.likedByUser
            )
        }
    }
}


