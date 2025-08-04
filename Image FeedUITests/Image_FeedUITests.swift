
import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication()
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app.launch()
    }
    
    func testAuth() throws {
        app.buttons["Authenticate"].tap()
        
        sleep(3)
       
        let webView = app.webViews["UnsplashWebView"].exists ? app.webViews["UnsplashWebView"] : app.webViews.element
        
        if !webView.waitForExistence(timeout: 15) {
            
            let anyWebView = app.webViews.element
            XCTAssertTrue(anyWebView.waitForExistence(timeout: 10), "WebView не найден")
        }

        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        
        loginTextField.tap()
        sleep(2)
        loginTextField.typeText("")
        sleep(1)
        app.typeText("\t")
        sleep(1)
        webView.swipeUp()
        sleep(2)
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        
        passwordTextField.tap()
        sleep(2)
        passwordTextField.typeText("")
        sleep(1)
        app.typeText("\t")
        sleep(1)
        webView.swipeUp()
        sleep(2)
        
        webView.buttons["Login"].tap()
        
        sleep(5)
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }
    
    func testFeed() throws {
        let tablesQuery = app.tables
        let firstCell = tablesQuery.cells.element(boundBy: 0)
        
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15))
        
        sleep(3)
       
        let secondCell = tablesQuery.cells.element(boundBy: 1)
        XCTAssertTrue(secondCell.waitForExistence(timeout: 10))
        let likeButton = secondCell.buttons["Like"]
       
        let likeButtonExists = likeButton.waitForExistence(timeout: 10)
        XCTAssertTrue(likeButtonExists, "Кнопка лайка не найдена")
        
        
        if !likeButton.isHittable {
            app.swipeUp()
            sleep(2)
            
            if !likeButton.isHittable {
                app.swipeUp()
                sleep(2)
            }
        }
        
       
        XCTAssertTrue(likeButton.isHittable, "Кнопка лайка недоступна для нажатия")
        
        likeButton.tap()
        sleep(2)
       
        likeButton.tap()
        sleep(2)
        
        let image = firstCell.images.firstMatch
        XCTAssertTrue(image.waitForExistence(timeout: 10))
        image.tap()
        sleep(5)
        let fullscreenImage = app.images.firstMatch
        fullscreenImage.pinch(withScale: 3, velocity: 1)
        fullscreenImage.pinch(withScale: 0.5, velocity: -1)
        let backButton = app.buttons["Backward"]
        backButton.tap()
    }
    
    func testProfile() throws {
        sleep(5)
        app.tabBars.buttons.element(boundBy: 1).tap()
       
        XCTAssertTrue(app.staticTexts["ProfileName"].exists)
        XCTAssertTrue(app.staticTexts["ProfileUsername"].exists)
        
        app.buttons["logout"].tap()
        
        app.alerts["Пока, пока!"].scrollViews.otherElements.buttons["Да"].tap()
    }
}
