//
//  DashboardUITest.swift
//  sphinxUITests
//
//  Created by Oko-osi Korede on 01/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import XCTest

final class DashboardUITest: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        app.launch()
        continueAfterFailure = false
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
    
    func testTappingFriendsTabShowFriendsChat() {
        let friendsStaticText = app/*@START_MENU_TOKEN@*/.staticTexts["Friends"]/*[[".buttons[\"Friends\"].staticTexts[\"Friends\"]",".staticTexts[\"Friends\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        friendsStaticText.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Feed"]/*[[".buttons[\"Feed\"].staticTexts[\"Feed\"]",".staticTexts[\"Feed\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        friendsStaticText.tap()
        let chatsContainerVC = app.otherElements["ChatsContainerViewController"]
        XCTAssertTrue(chatsContainerVC.exists)
    }
    
    func testTappingTribesTabShowTribesChats() {
        app/*@START_MENU_TOKEN@*/.staticTexts["Tribes"]/*[[".buttons[\"Tribes\"].staticTexts[\"Tribes\"]",".staticTexts[\"Tribes\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let chatsContainerVC = app.otherElements["ChatsContainerViewController"]
        XCTAssertTrue(chatsContainerVC.exists)
    }
    
    func testTappingAddTribesShowDiscoverTribesView() {
        app/*@START_MENU_TOKEN@*/.staticTexts["Tribes"]/*[[".buttons[\"Tribes\"].staticTexts[\"Tribes\"]",".staticTexts[\"Tribes\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Add Tribe"]/*[[".buttons[\"Add Tribe\"].staticTexts[\"Add Tribe\"]",".staticTexts[\"Add Tribe\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let discoverTribesWebVC = app.otherElements["DiscoverTribesWebViewController"]
        XCTAssertTrue(discoverTribesWebVC.exists)
    }
    
    func testTappingLeftArrowButtonBottomBarShowRequestAmountView() {
        app.buttons["bottomBar1"].tap()
        let createInvoiceVC = app.otherElements["CreateInvoiceViewController"]
        XCTAssertTrue(createInvoiceVC.exists)
        app/*@START_MENU_TOKEN@*/.buttons[""]/*[[".otherElements[\"CreateInvoiceViewController\"].buttons[\"\"]",".buttons[\"\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func testTappingRightArrowButtonBottomBarShowRequestAmountView() {
        app.buttons["bottomBar4"].tap()
        let newQRScannerVC = app.otherElements["NewQRScannerViewController"]
        XCTAssertTrue(newQRScannerVC.exists)
        newQRScannerVC.children(matching: .other).element(boundBy: 0)/*@START_MENU_TOKEN@*/.staticTexts[""]/*[[".buttons[\"\"].staticTexts[\"\"]",".staticTexts[\"\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func testTappingScannerButtonBottomBarShowRequestAmountView() {
        app.buttons["bottomBar3"].tap()
        let newQRScannerVC = app.otherElements["NewQRScannerViewController"]
        XCTAssertTrue(newQRScannerVC.exists)
        newQRScannerVC.children(matching: .other).element(boundBy: 0)/*@START_MENU_TOKEN@*/.staticTexts[""]/*[[".buttons[\"\"].staticTexts[\"\"]",".staticTexts[\"\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
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
