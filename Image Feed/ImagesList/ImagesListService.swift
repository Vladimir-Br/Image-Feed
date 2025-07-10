
import UIKit

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
    
    // MARK: - Networking
    func fetchPhotosNextPage() {
        // Если уже идёт загрузка — выходим
        if isLoading { return }
        isLoading = true
        
        // Определяем номер следующей страницы
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        // Здесь должен быть реальный сетевой запрос
        // Для примера — эмуляция задержки и получения новых фото
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            // Эмулируем получение новых фото (пустой массив)
            let newPhotos: [Photo] = [] // Здесь должен быть результат парсинга
            
            DispatchQueue.main.async {
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                self.isLoading = false
                NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
            }
        }
    }
}

func tableView(
  _ tableView: UITableView,
  willDisplay cell: UITableViewCell,
  forRowAt indexPath: IndexPath
) {
    // ...
}
