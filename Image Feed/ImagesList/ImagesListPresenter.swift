
import Foundation
import ProgressHUD

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    
    private let imagesListService: ImagesListServiceProtocol
    private var notificationToken: NSObjectProtocol?
    private var currentPhotosCount = 0

    init(imagesListService: ImagesListServiceProtocol) {
        self.imagesListService = imagesListService
    }

    func viewDidLoad() {
        notificationToken = NotificationCenter.default.addObserver(
            forName: type(of: imagesListService).didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableView()
        }
        fetchNextPage()
    }

    func fetchNextPage() {
        imagesListService.fetchPhotosNextPage()
    }

    func didTapLike(at indexPath: IndexPath) {
        guard let photo = photo(at: indexPath) else { return }
        UIBlockingProgressHUD.show()
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            UIBlockingProgressHUD.dismiss()
            switch result {
            case .success:
                let isLiked = self.imagesListService.photos[indexPath.row].isLiked
                self.view?.setIsLiked(for: indexPath, isLiked: isLiked)
            case .failure:
                self.view?.showErrorAlert(message: "Не удалось изменить лайк")
            }
        }
    }

    func didSelectRow(at indexPath: IndexPath) {
        view?.performSegueToSingleImage(with: indexPath)
    }

    func numberOfPhotos() -> Int {
        return imagesListService.photos.count
    }

    func photo(at indexPath: IndexPath) -> Photo? {
        guard indexPath.row < imagesListService.photos.count else { return nil }
        return imagesListService.photos[indexPath.row]
    }

    private func updateTableView() {
        let oldCount = currentPhotosCount
        let newCount = imagesListService.photos.count
        
        if oldCount != newCount {
            currentPhotosCount = newCount
            view?.updateTableViewAnimated(oldCount: oldCount, newCount: newCount)
        }
    }

    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
