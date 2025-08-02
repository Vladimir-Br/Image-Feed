
import Image_Feed
import Foundation

final class ImagesListServiceSpy: ImagesListServiceProtocol {
    var photos: [Photo] = []
    static var didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    var fetchPhotosNextPageCalled = false
    var changeLikeCalled = false

    // Замыкание, которое можно переопределить в тесте
    var changeLikeStub: ((String, Bool, @escaping (Result<Void, Error>) -> Void) -> Void)?

    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        changeLikeCalled = true
        if let stub = changeLikeStub {
            stub(photoId, isLike, completion)
        } else {
            completion(.success(()))
        }
    }
}

