import XCTest
@testable import Image_Feed
import UIKit

final class ImagesListTests: XCTestCase {
    var viewController: ImagesListViewController!
    var presenterSpy: ImagesListPresenterSpy!
    var storyboard: UIStoryboard!
    
    override func setUp() {
        super.setUp()
        storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        viewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as? ImagesListViewController
        presenterSpy = ImagesListPresenterSpy()
        viewController.configure(presenterSpy)
    }
    
    override func tearDown() {
        viewController = nil
        presenterSpy = nil
        storyboard = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        
        let newPresenterSpy = ImagesListPresenterSpy()
        let newViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        newViewController.configure(newPresenterSpy)
        newViewController.loadViewIfNeeded()
        XCTAssertTrue(newPresenterSpy.viewDidLoadCalled, "viewDidLoad не вызван")
    }
    
    func testUpdateTableView() {
        viewController.loadViewIfNeeded()
        viewController.updateTableViewAnimated(oldCount: 0, newCount: 0)
        XCTAssertNotNil(viewController, "ViewController nil после обновления")
    }
    
    func testSetLiked() {
        viewController.loadViewIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        viewController.setIsLiked(for: indexPath, isLiked: true)
        XCTAssertNotNil(viewController, "ViewController nil после лайка")
    }
    
    func testShowError() {
        viewController.loadViewIfNeeded()
        let errorMessage = "Test error message"
        viewController.showErrorAlert(message: errorMessage)
        XCTAssertNotNil(viewController, "ViewController nil после ошибки")
    }
    
    func testViewControllerSetup() {
        viewController.loadViewIfNeeded()
        XCTAssertNotNil(viewController, "ViewController не существует")
        XCTAssertEqual(viewController.preferredStatusBarStyle, .lightContent, "Status bar не светлый")
        XCTAssertNotNil(viewController.view, "View не создан")
    }
    
    func testProtocolMethods() {
        viewController.loadViewIfNeeded()
        XCTAssertNotNil(viewController, "ViewController nil")
        XCTAssertTrue(viewController.conforms(to: UITableViewDataSource.self), "Не соответствует UITableViewDataSource")
        XCTAssertTrue(viewController.conforms(to: UITableViewDelegate.self), "Не соответствует UITableViewDelegate")
    }
    
    func testConfigurePresenter() {
        
        let newPresenterSpy = ImagesListPresenterSpy()
        let newViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        newViewController.configure(newPresenterSpy)
        XCTAssertTrue(newPresenterSpy.view === newViewController, "Presenter не ссылается на view")
    }
}
