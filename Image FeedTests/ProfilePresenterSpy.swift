@testable import Image_Feed
import Foundation

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    private(set) var viewDidLoadCalled = false
    private(set) var didTapLogoutButtonCalled = false
    private(set) var performLogoutCalled = false

    weak var view: ProfileViewControllerProtocol?

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didTapLogoutButton() {
        didTapLogoutButtonCalled = true
    }

    func performLogout() {
        performLogoutCalled = true
    }
}
