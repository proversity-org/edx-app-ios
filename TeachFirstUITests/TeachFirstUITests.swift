//
//  TeachFirstUITests.swift
//  TeachFirstUITests
//
//  Created by José Antonio González on 11/11/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

class TeachFirstUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
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
        app.navigationBars["Sign in to Teach First"].buttons["Close"].tap()
    }
    
}
