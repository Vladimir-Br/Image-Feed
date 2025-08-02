import XCTest
@testable import Image_Feed

final class ImagesListTests: XCTestCase {
    
    func testViewDidLoadFetchesPhotos() {
        // given
        let service = ImagesListServiceSpy()
        let view = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = view
        
        // when
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(service.fetchPhotosNextPageCalled, "fetchPhotosNextPage() должен быть вызван при загрузке")
    }

    func testFetchNextPage() {
        // given
        let service = ImagesListServiceSpy()
        let presenter = ImagesListPresenter(imagesListService: service)

        // when
        presenter.fetchNextPage()

        // then
        XCTAssertTrue(service.fetchPhotosNextPageCalled)
    }

    func testLikeSuccess() {
        // given
        let service = ImagesListServiceSpy()
        let view = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = view

        let photo = Photo(id: "1", size: .init(width: 10, height: 10), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
        service.photos = [photo]
        let indexPath = IndexPath(row: 0, section: 0)

        // when
        presenter.didTapLike(at: indexPath)

        // then
        XCTAssertTrue(service.changeLikeCalled)
        XCTAssertTrue(view.setIsLikedCalled)
    }

    func testLikeFailure() {
        // given
        let service = ImagesListServiceSpy()
        let view = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = view

        service.changeLikeStub = { _, _, completion in
            completion(.failure(MockError.test))
        }

        let photo = Photo(id: "1", size: .init(width: 10, height: 10), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
        service.photos = [photo]
        let indexPath = IndexPath(row: 0, section: 0)

        // when
        presenter.didTapLike(at: indexPath)

        // then
        XCTAssertTrue(view.showErrorAlertCalled)
    }

    func testSelectRow() {
        // given
        let service = ImagesListServiceSpy()
        let view = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = view

        let indexPath = IndexPath(row: 0, section: 0)
        service.photos = [Photo(id: "1", size: .init(width: 1, height: 1), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)]

        // when
        presenter.didSelectRow(at: indexPath)

        // then
        XCTAssertTrue(view.performSegueCalled)
    }

    func testPhotosCount() {
        // given
        let service = ImagesListServiceSpy()
        let presenter = ImagesListPresenter(imagesListService: service)

        service.photos = [
            Photo(id: "1", size: .init(width: 1, height: 1), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false),
            Photo(id: "2", size: .init(width: 1, height: 1), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
        ]

        // when
        let count = presenter.numberOfPhotos()

        // then
        XCTAssertEqual(count, 2)
    }

    func testGetPhoto() {
        // given
        let service = ImagesListServiceSpy()
        let presenter = ImagesListPresenter(imagesListService: service)

        let photo = Photo(id: "test", size: .init(width: 100, height: 200), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
        service.photos = [photo]

        // when
        let result = presenter.photo(at: IndexPath(row: 0, section: 0))

        // then
        XCTAssertEqual(result?.id, "test")
    }
}

// MARK: - Mock Error

enum MockError: Error {
    case test
}