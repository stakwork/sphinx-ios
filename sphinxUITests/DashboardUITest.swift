//
//  DashboardUITest.swift
//  sphinxUITests
//
//  Created by Oko-osi Korede on 01/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import XCTest

final class DashboardUITest: XCTestCase {

//    var app: XCUIApplication!
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        app.launch()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testTappingFeedsTabShowFeedContent() throws {
        let feedTab = app/*@START_MENU_TOKEN@*/.staticTexts["Feed"]/*[[".buttons[\"Feed\"].staticTexts[\"Feed\"]",".staticTexts[\"Feed\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        XCTAssertTrue(feedTab.exists)
        feedTab.tap()
        let dashboardFeedsContainerVC = app.otherElements["DashboardFeedsContainerViewController"]
        XCTAssertTrue(dashboardFeedsContainerVC.exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
