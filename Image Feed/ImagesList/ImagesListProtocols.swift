
import Foundation
import UIKit

// MARK: - View Protocol

protocol ImagesListViewControllerProtocol: AnyObject {
    /// Обновляет таблицу с анимацией вставки новых ячеек
    func updateTableViewAnimated(oldCount: Int, newCount: Int)

    /// Устанавливает статус "лайкнуто" для конкретной ячейки
    func setIsLiked(for indexPath: IndexPath, isLiked: Bool)

    /// Показывает ошибку пользователю
    func showErrorAlert(message: String)

    /// Переход к экрану просмотра изображения
    func performSegueToSingleImage(with indexPath: IndexPath)
}

// MARK: - Presenter Protocol

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }

    /// Вызывается при загрузке ViewController'а
    func viewDidLoad()

    /// Загружает следующую страницу изображений
    func fetchNextPage()

    /// Обрабатывает нажатие на кнопку лайка
    func didTapLike(at indexPath: IndexPath)

    /// Обрабатывает выбор строки таблицы
    func didSelectRow(at indexPath: IndexPath)

    /// Количество изображений
    func numberOfPhotos() -> Int

    /// Фото по индексу
    func photo(at indexPath: IndexPath) -> Photo?
}

// MARK: - Service Protocol

protocol ImagesListServiceProtocol: AnyObject {
    /// Все загруженные фотографии
    var photos: [Photo] { get }

    /// Уведомление об изменении данных
    static var didChangeNotification: Notification.Name { get }

    /// Загрузка следующей страницы
    func fetchPhotosNextPage()

    /// Изменение лайка
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

