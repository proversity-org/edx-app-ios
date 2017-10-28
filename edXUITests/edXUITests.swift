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
        app.buttons["Already have an account? Sign in"].tap()
        snapshot("login")
        let userFieldTextField = app.textFields["User name or e-mail address"]
        userFieldTextField.tap()
        userFieldTextField.typeText("jagonzalr")
        let passwordFieldSecureTextField = app.secureTextFields["Password"]
        passwordFieldSecureTextField.tap()
        passwordFieldSecureTextField.typeText("Fender182")
        app.buttons["Sign In"].tap()
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: app.navigationBars["My Powerful Insights"], handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
        if (app.navigationBars["My Powerful Insights"].exists) {
            app.navigationBars["My Powerful Insights"].buttons["Navigation Menu"].tap()
            app.cells.buttons["MY POWERFUL INSIGHTS"].tap()
            app.navigationBars["My Powerful Insights"].buttons["Navigation Menu"].tap()
            app.cells.buttons["MY POWERFUL INSIGHTS"].tap()
            app.navigationBars["My Powerful Insights"].buttons["Navigation Menu"].tap()
            app.cells.buttons["MY POWERFUL INSIGHTS"].tap()
            app.navigationBars["My Powerful Insights"].buttons["Navigation Menu"].tap()
            app.cells.buttons["MY POWERFUL INSIGHTS"].tap()
            snapshot("courses")
            app.navigationBars["My Powerful Insights"].buttons["Navigation Menu"].tap()
            snapshot("profile")
            app.buttons["LOGOUT"].tap()
            userFieldTextField.tap()
            userFieldTextField.typeText("")
        }
    }
}