//
//  YoungEnterpriseUITests.swift
//  YoungEnterpriseUITests
//
//  Created by José Antonio González on 1/1/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest

class YoungEnterpriseUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
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
        app.buttons["login"].tap()
        snapshot("login")
        app.navigationBars["Sign In"].buttons["Close"].tap()
    }
    
}
