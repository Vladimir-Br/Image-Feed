import UIKit
import ProgressHUD

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    @IBOutlet private weak var tableView: UITableView!
    
    private var photos: [Photo] = []
    private let imagesListService = ImagesListService()
    private var notificationToken: NSObjectProtocol?
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        notificationToken = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.updateTableViewAnimated()
        }
        imagesListService.fetchPhotosNextPage()
    }
    
    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Неверный destination для segue")
                return
            }
            // Здесь можно будет передавать изображение по url, когда будет реализована загрузка картинок
            viewController.image = nil
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            let indexPaths = (oldCount..<newCount).map {
                IndexPath(row: $0, section: 0)
            }
            tableView.performBatchUpdates {
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }
}
 
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)

        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)

        return imageListCell
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        if let url = URL(string: photo.thumbImageURL) {
            cell.cellImage.kf.indicatorType = .activity
            cell.cellImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "Stub")
            ) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("[ImagesListViewController] Ошибка загрузки изображения: \(error)")
                }
            }
        } else {
            cell.cellImage.image = UIImage(named: "Stub")
        }
        cell.dateLabel.text = photo.createdAt.map { dateFormatter.string(from: $0) } ?? ""
        let likeImage = photo.isLiked ? UIImage(named: "button_like_yes") : UIImage(named: "button_like_no")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        // 1. Находим indexPath ячейки, по которой кликнули
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        // 2. Получаем объект Photo для этой ячейки
        let photo = photos[indexPath.row]
        
        // 3. Показываем лоадер, чтобы заблокировать UI
        UIBlockingProgressHUD.show()
        
        // 4. Вызываем метод сервиса для изменения лайка
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // 5. В случае успеха:
                // Синхронизируем наш массив photos с тем, что в сервисе.
                // Сервис должен сам обновить состояние лайка у фото внутри себя.
                self.photos = self.imagesListService.photos
                
                // Обновляем вид кнопки в ячейке через новый метод
                cell.setIsLiked(self.photos[indexPath.row].isLiked)
                
                // Убираем лоадер
                UIBlockingProgressHUD.dismiss()
                
            case .failure:
                // 6. В случае ошибки:
                // Убираем лоадер
                UIBlockingProgressHUD.dismiss()
                
                // TODO: Показать пользователю алерт об ошибке
                print("[ImagesListViewController] Ошибка изменения лайка")
            }
        }
    }
}
