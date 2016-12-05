//
//  Family_Mosaic___ProversityUITests.swift
//  Family Mosaic | ProversityUITests
//
//  Created by José Antonio González on 12/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

class Family_Mosaic___ProversityUITests: XCTestCase {
        
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
        app.navigationBars["Sign in to Family Mosaic"].buttons["Close"].tap()
    }
    
}
