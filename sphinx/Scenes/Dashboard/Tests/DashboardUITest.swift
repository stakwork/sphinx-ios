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
        app.terminate()
    }
    
    func testDashboardUI() {
        let friendSearchcontent = "Alejandro"
        //MARK: - test Tapping Feeds Tab Shows FeedContent
        let feedTab = app.staticTexts["Feed"]
        XCTAssertTrue(feedTab.exists)
        feedTab.tap()
        let dashboardFeedsContainerVC = app.otherElements["DashboardFeedsContainerViewController"]
        XCTAssertTrue(dashboardFeedsContainerVC.exists)
        
        //MARK: - test Tapping Friends Tab Shows Friends Chat
        let friendsStaticText = app/*@START_MENU_TOKEN@*/.staticTexts["Friends"]/*[[".buttons[\"Friends\"].staticTexts[\"Friends\"]",".staticTexts[\"Friends\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        friendsStaticText.tap()
        let chatsContainerVC = app.otherElements["ChatsContainerViewController"]
        XCTAssertTrue(chatsContainerVC.exists)
        
        //MARK: - test Tapping Tribes Tab Shows Tribes Chats
        app/*@START_MENU_TOKEN@*/.staticTexts["Tribes"]/*[[".buttons[\"Tribes\"].staticTexts[\"Tribes\"]",".staticTexts[\"Tribes\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCTAssertTrue(chatsContainerVC.exists)
        
        //MARK: - test Tapping Add Tribes Shows Discover Tribes View
        app/*@START_MENU_TOKEN@*/.staticTexts["Tribes"]/*[[".buttons[\"Tribes\"].staticTexts[\"Tribes\"]",".staticTexts[\"Tribes\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Add Tribe"]/*[[".buttons[\"Add Tribe\"].staticTexts[\"Add Tribe\"]",".staticTexts[\"Add Tribe\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let discoverTribesWebVC = app.otherElements["DiscoverTribesWebViewController"]
        XCTAssertTrue(discoverTribesWebVC.exists)
        app.buttons["back"].tap()
        
        //MARK: - test Tapping Left Arrow Button on Bottom Bar Shows Request Amount View
        app.buttons["bottomBar1"].tap()
        let createInvoiceVC = app.otherElements["CreateInvoiceViewController"]
        XCTAssertTrue(createInvoiceVC.exists)
        app/*@START_MENU_TOKEN@*/.buttons[""]/*[[".otherElements[\"CreateInvoiceViewController\"].buttons[\"\"]",".buttons[\"\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        //MARK: - test Tapping Right Arrow Button on Bottom Bar Shows Request Amount View
        app.buttons["bottomBar4"].tap()
        let newQRScannerVC = app.otherElements["NewQRScannerViewController"]
        XCTAssertTrue(newQRScannerVC.exists)
        newQRScannerVC.children(matching: .other).element(boundBy: 0)/*@START_MENU_TOKEN@*/.staticTexts[""]/*[[".buttons[\"\"].staticTexts[\"\"]",".staticTexts[\"\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        //MARK: - test Tapping Scanner Button on Bottom Bar Shows Request Amount View
        app.buttons["bottomBar3"].tap()
        XCTAssertTrue(newQRScannerVC.exists)
        newQRScannerVC.children(matching: .other).element(boundBy: 0)/*@START_MENU_TOKEN@*/.staticTexts[""]/*[[".buttons[\"\"].staticTexts[\"\"]",".staticTexts[\"\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        //MARK: - test Tapping Transactions on Bottom Bar Shows Transaction View
        app.buttons["bottomBar2"].tap()
        let historyVC = app.otherElements["HistoryViewController"]
        XCTAssertTrue(historyVC.exists)
        historyVC.children(matching: .other).element.children(matching: .button).element.tap()
        
        //MARK: - Search Field on Friends Tab Filter Chat Row based on Search Item
        let searchTextField = app.textFields["Search"]
        friendsStaticText.tap()
        searchTextField.tap()
        searchTextField.typeText(friendSearchcontent)
        sleep(1)
        let result = app.collectionViews.cells.staticTexts["Alejandro"]
        XCTAssertTrue(result.exists)
        sleep(1)
        app.terminate()
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
