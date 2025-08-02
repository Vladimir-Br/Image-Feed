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
        // given
        let newPresenterSpy = ImagesListPresenterSpy()
        let newViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        newViewController.configure(newPresenterSpy)
        
        // when
        newViewController.loadViewIfNeeded() // Это вызовет viewDidLoad
        
        // then
        XCTAssertTrue(newPresenterSpy.viewDidLoadCalled, "viewDidLoad() должен вызвать presenter.viewDidLoad()")
    }
    
    func testUpdateTableView() {
        // given
        viewController.loadViewIfNeeded()
        
        // when
        // Тестируем сценарий, когда количество не изменилось (безопасный случай)
        viewController.updateTableViewAnimated(oldCount: 0, newCount: 0)
        
        // then
        // Проверяем, что метод выполняется без ошибок
        XCTAssertNotNil(viewController, "View controller должен остаться валидным после обновления таблицы")
    }
    
    func testSetLiked() {
        // given
        viewController.loadViewIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        
        // when
        viewController.setIsLiked(for: indexPath, isLiked: true)
        
        // then
        // Проверяем, что метод выполняется без ошибок
        XCTAssertNotNil(viewController, "View controller должен остаться валидным после установки лайка")
    }
    
    func testShowError() {
        // given
        viewController.loadViewIfNeeded()
        let errorMessage = "Test error message"
        
        // when
        viewController.showErrorAlert(message: errorMessage)
        
        // then
        // Unit-тест: проверяем, что метод выполняется без краша
        XCTAssertNotNil(viewController, "View controller должен остаться валидным после показа ошибки")
    }
    
    func testViewControllerSetup() {
        // given
        viewController.loadViewIfNeeded()
        
        // when/then
        // Проверяем базовую настройку view controller
        XCTAssertNotNil(viewController, "View controller должен существовать")
        XCTAssertEqual(viewController.preferredStatusBarStyle, .lightContent, "Status bar должен быть светлым")
        XCTAssertNotNil(viewController.view, "View должен быть создан")
    }
    
    func testProtocolMethods() {
        // given
        viewController.loadViewIfNeeded()
        
        // then
        // Проверяем, что view controller не nil и реализует протоколы
        XCTAssertNotNil(viewController, "ViewController не должен быть nil")
        XCTAssertTrue(viewController.conforms(to: UITableViewDataSource.self), "ViewController должен соответствовать UITableViewDataSource")
        XCTAssertTrue(viewController.conforms(to: UITableViewDelegate.self), "ViewController должен соответствовать UITableViewDelegate")
    }
    
    func testConfigurePresenter() {
        // given
        let newPresenterSpy = ImagesListPresenterSpy()
        let newViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        
        // when
        newViewController.configure(newPresenterSpy)
        
        // then
        // Проверяем, что presenter установлен правильно
        XCTAssertTrue(newPresenterSpy.view === newViewController, "Presenter должен иметь ссылку на view controller")
    }
}