@testable import Image_Feed
import Foundation

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    // MARK: - Properties
    weak var view: ImagesListViewControllerProtocol?
    
    // MARK: - Call tracking
    private(set) var viewDidLoadCalled = false
    private(set) var fetchNextPageCalled = false
    private(set) var didTapLikeCalled = false
    private(set) var didSelectRowCalled = false
    private(set) var numberOfPhotosCalled = false
    private(set) var photoCalled = false
    
    // MARK: - Parameters tracking
    private(set) var receivedIndexPath: IndexPath?
    
    // MARK: - Return values for testing
    var numberOfPhotosReturnValue = 0
    var photoReturnValue: Photo?
    
    // MARK: - Protocol methods
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func fetchNextPage() {
        fetchNextPageCalled = true
    }
    
    func didTapLike(at indexPath: IndexPath) {
        didTapLikeCalled = true
        receivedIndexPath = indexPath
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        didSelectRowCalled = true
        receivedIndexPath = indexPath
    }
    
    func numberOfPhotos() -> Int {
        numberOfPhotosCalled = true
        return numberOfPhotosReturnValue
    }
    
    func photo(at indexPath: IndexPath) -> Photo? {
        photoCalled = true
        receivedIndexPath = indexPath
        return photoReturnValue
    }
}