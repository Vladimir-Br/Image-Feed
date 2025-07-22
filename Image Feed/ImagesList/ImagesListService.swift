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
    var isLiked: Bool
}

final class ImagesListService {
    
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let shared = ImagesListService()
    private init() {}
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var isLoading = false
    private var fetchPhotosTask: URLSessionTask?
    private var likeTask: URLSessionTask?
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    func fetchPhotosNextPage() {
        guard !isLoading else { return }
        isLoading = true
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makePhotosRequest(page: nextPage) else {
            isLoading = false
            print("[ImagesListService.fetchPhotosNextPage]: [invalidRequest] [page: \(nextPage)]")
            return
        }
        
        fetchPhotosTask?.cancel()
        
        fetchPhotosTask = performRequest(request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                defer {
                    self.isLoading = false
                    self.fetchPhotosTask = nil
                }
                
                switch result {
                case .success(let photoResults):
                    let newPhotos = self.convertToPhotos(photoResults)
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
                    
                case .failure(let error):
                    print("[ImagesListService.fetchPhotosNextPage]: [\(error)] [page: \(nextPage)]")
                }
            }
        }
        
        fetchPhotosTask?.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            let error = NetworkError.invalidURL
            print("[ImagesListService.changeLike]: [\(error)] [photoId: \(photoId), isLike: \(isLike)]")
            completion(.failure(error))
            return
        }
        
        guard let request = authorizedRequest(url: url, method: isLike ? "POST" : "DELETE") else {
            let error = NetworkError.invalidResponse
            print("[ImagesListService.changeLike]: [\(error)] [photoId: \(photoId), isLike: \(isLike)]")
            completion(.failure(error))
            return
        }
        
        likeTask?.cancel()
        
        likeTask = performRequest(request) { [weak self] (result: Result<Data, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { self.likeTask = nil }
                switch result {
                case .success:
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let updatedPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            isLiked: !photo.isLiked
                        )
                        self.photos = self.photos.withReplaced(itemAt: index, newValue: updatedPhoto)
                    }
                    completion(.success(()))
                    
                case .failure(let error):
                    print("[ImagesListService.changeLike]: [\(error)] [photoId: \(photoId), isLike: \(isLike)]")
                    completion(.failure(error))
                }
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
        likeTask?.cancel()
        likeTask = nil
    }
    
    private func authorizedRequest(url: URL, method: String = "GET") -> URLRequest? {
        guard let token = OAuth2TokenStorage.shared.token else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func makePhotosRequest(page: Int) -> URLRequest? {
        var urlComponents = URLComponents(string: "https://api.unsplash.com/photos")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else { return nil }
        
        return authorizedRequest(url: url, method: "GET")
    }
    
    private func convertToPhotos(_ photoResults: [PhotoResult]) -> [Photo] {
        photoResults.map { photoResult in
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
    
    private func performRequest<T: Decodable>(_ request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) -> URLSessionTask {
        return URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.urlRequestError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(NetworkError.httpStatusCode(code)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            if T.self == Data.self {
                guard let typedData = data as? T else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                completion(.success(typedData))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                print("[ImagesListService.performRequest]: [decodingError] [data: \(String(data: data, encoding: .utf8) ?? "invalid encoding")]")
                completion(.failure(error))
            }
        }
    }
}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var array = self
        array[index] = newValue
        return array
    }
}
