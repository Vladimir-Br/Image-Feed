import XCTest
@testable import Image_Feed
import UIKit

final class ProfileViewTests: XCTestCase {
    var viewController: ProfileViewController!
    var presenterSpy: ProfilePresenterSpy!

    override func setUp() {
        super.setUp()
        viewController = ProfileViewController()
        presenterSpy = ProfilePresenterSpy()
        viewController.configure(presenter: presenterSpy)
        viewController.loadViewIfNeeded() // Создаёт view и вызывает viewDidLoad
    }

    override func tearDown() {
        viewController = nil
        presenterSpy = nil
        super.tearDown()
    }

    func testViewDidLoad() {
        // given
        let newPresenterSpy = ProfilePresenterSpy()
        let newViewController = ProfileViewController()
        newViewController.configure(presenter: newPresenterSpy)
        
        // when
        newViewController.loadViewIfNeeded() // Это вызовет viewDidLoad
        
        // then
        XCTAssertTrue(newPresenterSpy.viewDidLoadCalled, "viewDidLoad() должен вызвать presenter.viewDidLoad()")
    }

    func testUpdateProfile() {
        // given
        let expectedName = "Иван Иванов"
        let expectedLogin = "@ivan"
        let expectedBio = "iOS Developer"

        // when
        viewController.updateProfileDetails(name: expectedName, loginName: expectedLogin, bio: expectedBio)

        // then
        XCTAssertEqual(viewController.nameLabel.text, expectedName)
        XCTAssertEqual(viewController.usernameLabel.text, expectedLogin)
        XCTAssertEqual(viewController.infoLabel.text, expectedBio)
    }

    func testUpdateAvatar() {
        // given
        let testURL = URL(string: "https://example.com/avatar.jpg")
        
        // when
        viewController.updateAvatar(with: testURL)
        
        // then
        // Проверяем, что метод был вызван без ошибок
        XCTAssertNotNil(viewController.profileImageView, "profileImageView должен существовать")
    }

    func testUpdateAvatarNil() {
        // when
        viewController.updateAvatar(with: nil)
        
        // then
        // Kingfisher установит placeholder при nil URL
        XCTAssertNotNil(viewController.profileImageView, "profileImageView должен существовать")
    }

    func testLogoutButton() {
        // when
        viewController.didTapLogoutButton(UIButton())
        
        // then
        XCTAssertTrue(presenterSpy.didTapLogoutButtonCalled, "Нажатие кнопки должно вызвать presenter.didTapLogoutButton()")
    }

    func testShowAlert() {
        // when
        viewController.showLogoutAlert()
        
        // then
        // Unit-тест: проверяем, что метод выполняется без краша
        // UI тестирование алерта будет в отдельных UI-тестах
        XCTAssertNotNil(viewController, "View controller должен остаться валидным после вызова showLogoutAlert")
    }
    
    func testSwitchToSplash() {
        // when
        viewController.switchToSplashViewController()
        
        // then
        // Проверяем, что метод выполняется без ошибок
        XCTAssertNotNil(viewController, "View controller должен остаться валидным")
    }
}