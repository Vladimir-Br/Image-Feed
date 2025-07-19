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
    static let shared = ImagesListService()
    private init() {}

    // MARK: - Properties
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var isLoading = false
    private var fetchPhotosTask: URLSessionTask?
    private var likeTask: URLSessionTask?

    // MARK: - Date Formatter
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    // MARK: - Networking
    func fetchPhotosNextPage() {
        guard !isLoading else { return }
        isLoading = true

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makeRequest(page: nextPage) else {
            isLoading = false
            return
        }

        fetchPhotosTask?.cancel()
        fetchPhotosTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
                }
            }

            if let error = error {
                print("[ImagesListService] Ошибка загрузки фотографий: \(error)")
                return
            }

            guard let data = data else {
                print("[ImagesListService] Нет данных в ответе")
                return
            }

            do {
                let photoResults = try JSONDecoder().decode([PhotoResult].self, from: data)
                let newPhotos = self.convertToPhotos(photoResults)
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                }
            } catch {
                print("[ImagesListService] Ошибка декодирования: \(error)")
            }
        }
        fetchPhotosTask?.resume()
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }

        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        likeTask?.cancel()
        likeTask = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    completion(.failure(NetworkError.urlRequestError(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    completion(.failure(NetworkError.httpStatusCode(statusCode)))
                    return
                }

                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    let photo = self.photos[index]
                    let newPhoto = Photo(
                        id: photo.id,
                        size: photo.size,
                        createdAt: photo.createdAt,
                        welcomeDescription: photo.welcomeDescription,
                        thumbImageURL: photo.thumbImageURL,
                        largeImageURL: photo.largeImageURL,
                        isLiked: !photo.isLiked
                    )
                    self.photos = self.photos.withReplaced(itemAt: index, newValue: newPhoto)
                }

                completion(.success(()))
            }
        }
        likeTask?.resume()
    }

    func clearImagesList() {
        photos = []
        lastLoadedPage = nil
        isLoading = false
        fetchPhotosTask?.cancel()
        fetchPhotosTask = nil
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
