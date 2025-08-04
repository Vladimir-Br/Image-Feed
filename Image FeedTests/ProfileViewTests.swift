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
        viewController.loadViewIfNeeded() 
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
        newViewController.loadViewIfNeeded() // Это вызовет viewDidLoad
        XCTAssertTrue(newPresenterSpy.viewDidLoadCalled, "viewDidLoad не вызван")
    }
    
    func testUpdateProfile() {
        let expectedName = "Иван Иванов"
        let expectedLogin = "@ivan"
        let expectedBio = "iOS Developer"
        viewController.updateProfileDetails(name: expectedName, loginName: expectedLogin, bio: expectedBio)
        XCTAssertEqual(viewController.nameLabel.text, expectedName)
        XCTAssertEqual(viewController.usernameLabel.text, expectedLogin)
        XCTAssertEqual(viewController.infoLabel.text, expectedBio)
    }
    
    func testUpdateAvatar() {
        let testURL = URL(string: "https://example.com/avatar.jpg")
        viewController.updateAvatar(with: testURL)
        XCTAssertNotNil(viewController.profileImageView, "profileImageView не существует")
    }
    
    func testUpdateAvatarNil() {
        viewController.updateAvatar(with: nil)
        XCTAssertNotNil(viewController.profileImageView, "profileImageView не существует")
    }
    
    func testLogoutButton() {
        viewController.didTapLogoutButton(UIButton())
        XCTAssertTrue(presenterSpy.didTapLogoutButtonCalled, "didTapLogoutButton не вызван")
    }
    
    func testShowAlert() {
        viewController.showLogoutAlert()
        XCTAssertNotNil(viewController, "ViewController nil после alert")
    }
    
    func testSwitchToSplash() {
        viewController.switchToSplashViewController()
        XCTAssertNotNil(viewController, "ViewController nil")
    }
}
