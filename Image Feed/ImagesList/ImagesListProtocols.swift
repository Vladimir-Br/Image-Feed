
import Foundation
import UIKit

public protocol ImagesListViewControllerProtocol: AnyObject {
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int)
    func setIsLiked(for indexPath: IndexPath, isLiked: Bool)
    func showErrorAlert(message: String)
    func performSegueToSingleImage(with indexPath: IndexPath)
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    func viewDidLoad()
    func fetchNextPage()
    func didTapLike(at indexPath: IndexPath)
    func didSelectRow(at indexPath: IndexPath)
    func numberOfPhotos() -> Int
    func photo(at indexPath: IndexPath) -> Photo?
}

public protocol ImagesListServiceProtocol: AnyObject {
    var photos: [Photo] { get }
    static var didChangeNotification: Notification.Name { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

