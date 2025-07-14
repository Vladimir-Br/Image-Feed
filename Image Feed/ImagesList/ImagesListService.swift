
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

final class ImagesListService {
    // MARK: - Notifications
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    // MARK: - Properties
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var isLoading: Bool = false
    
    // MARK: - Date Formatter
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

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
                    print("[ImagesListService] Ошибка загрузки фотографий: \(error)")
                }
                
                self.isLoading = false
                NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
            }
        }
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        // Получаем токен авторизации
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }

        // Формируем URL
        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // Создаём запрос
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Выполняем запрос
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(NetworkError.urlRequestError(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                    return
                }

                // После успешного запроса обновляем массив photos
                // Поиск индекса элемента
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    // Текущий элемент
                    let photo = self.photos[index]
                    // Копия элемента с инвертированным значением isLiked
                    let newPhoto = Photo(
                        id: photo.id,
                        size: photo.size,
                        createdAt: photo.createdAt,
                        welcomeDescription: photo.welcomeDescription,
                        thumbImageURL: photo.thumbImageURL,
                        largeImageURL: photo.largeImageURL,
                        isLiked: !photo.isLiked
                    )
                    // Заменяем элемент в массиве
                    self.photos = self.photos.withReplaced(itemAt: index, newValue: newPhoto)
                }
                
                completion(.success(()))
            }
        }.resume()
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

// MARK: - Array Extension
extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var array = self
        array.replaceSubrange(index...index, with: [newValue])
        return array
    }
}


