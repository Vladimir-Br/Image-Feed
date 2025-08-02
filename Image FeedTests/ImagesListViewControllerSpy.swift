
import Image_Feed
import Foundation

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var updateTableViewAnimatedCalled = false
    var setIsLikedCalled = false
    var showErrorAlertCalled = false
    var performSegueCalled = false
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        updateTableViewAnimatedCalled = true
    }
    
    func setIsLiked(for indexPath: IndexPath, isLiked: Bool) {
        setIsLikedCalled = true
    }
    
    func showErrorAlert(message: String) {
        showErrorAlertCalled = true
    }
    
    func performSegueToSingleImage(with indexPath: IndexPath) {
        performSegueCalled = true
    }
}
