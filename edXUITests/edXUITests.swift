//
//  edXUITests.swift
//  edXUITests
//
//  Created by Pro_Dev on 2017/05/29.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest

class edXUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        snapshot("splash")
        app/*@START_MENU_TOKEN@*/.buttons["LoginSpashViewController:sign-up-button"]/*[[".otherElements[\"splash-screen\"]",".buttons[\"Already have an account? Sign in\"]",".buttons[\"LoginSpashViewController:sign-up-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("login")
        let emailTextField = app/*@START_MENU_TOKEN@*/.textFields["LoginViewController:email-text-field"]/*[[".otherElements[\"login-screen\"]",".scrollViews[\"LoginViewController:main-scroll-view\"]",".textFields[\"Username or e-mail address\"]",".textFields[\"LoginViewController:email-text-field\"]"],[[[-1,3],[-1,2],[-1,1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1,2]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/
        emailTextField.tap()
        emailTextField.typeText("jagonzalr")
        let passwordTextField = app/*@START_MENU_TOKEN@*/.secureTextFields["LoginViewController:password-text-field"]/*[[".otherElements[\"login-screen\"]",".scrollViews[\"LoginViewController:main-scroll-view\"]",".secureTextFields[\"Password\"]",".secureTextFields[\"LoginViewController:password-text-field\"]"],[[[-1,3],[-1,2],[-1,1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1,2]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/
        passwordTextField.tap()
        passwordTextField.typeText("Fender182")
        app/*@START_MENU_TOKEN@*/.buttons["LoginViewController:login-button"]/*[[".otherElements[\"login-screen\"]",".scrollViews[\"LoginViewController:main-scroll-view\"]",".buttons[\"Sign In\"]",".buttons[\"LoginViewController:login-button\"]"],[[[-1,3],[-1,2],[-1,1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1,2]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: app.navigationBars["Courses"], handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
        if (app.navigationBars["Courses"].exists) {
            sleep(20)
            let coursesNavigationBar = app.navigationBars["Courses"]
            snapshot("courses")
            coursesNavigationBar/*@START_MENU_TOKEN@*/.buttons["EnrolledTabBarViewController:account-button"]/*[[".buttons[\"Account\"]",".buttons[\"EnrolledTabBarViewController:account-button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            snapshot("account")
            app.tables["AccountViewController:table-view"]/*@START_MENU_TOKEN@*/.staticTexts["Logout"]/*[[".cells.matching(identifier: \"AccountViewController:table-cell\").staticTexts[\"Logout\"]",".staticTexts[\"Logout\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        }
    }
}
