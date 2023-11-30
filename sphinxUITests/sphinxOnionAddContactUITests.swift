//
//  sphinxOnionAddContactUITests.swift
//  sphinxUITests
//
//  Created by James Carucci on 11/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import XCTest

class sphinxOnionAddContactUITests: XCTestCase {

    private var app : XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Launch the app
        app = XCUIApplication()
        app.launch()
        
        //SignupHelper.step = SignupHelper.SignupStep.Start.rawValue

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_add_v2_contact_from_hamburger_menu(){
        //MARK: Important! Must start from a logged in account with 0 contacts!!
        //TODO: figure out how to automate the entire setup and clean up process!!
//        do{
//            try sphinxOnionAccountCreateUITests().test_fresh_launch_test_v2_flow_import_press_ok_complete_sign_up_UI(importedApp: app)
//        }
//        catch{
//            XCTFail("couldn't perform dependent test + setup")
//        }
        sleep(3)//let system start up
        let chatListHamburgerMenu = app.buttons["chatListHamburgerMenu"]
        XCTAssertTrue(chatListHamburgerMenu.exists)
        chatListHamburgerMenu.tap()
        sleep(3)
        
        let addFriendRowButton = app.cells["LeftMenuAddFriendTableViewCell-3"]
        //let addFriendRowButton = app.buttons["addFriendRowButton"]
        XCTAssertTrue(addFriendRowButton.exists)
        addFriendRowButton.tap()
        sleep(2)
        
        let existingUserButton = app.buttons["existingUserButton"]
        XCTAssertTrue(existingUserButton.exists)
        existingUserButton.tap()
        

        
        let nickNameTextField = app.textFields["nickNameTextField"]
        let addressTextField = app.textFields["addressTextField"]
        let routeHintTextField = app.textFields["routeHintTextField"]
        let saveToContactsContainer = app.otherElements["saveToContactsContainer"]
        
        sleep(2)//give time to set up
        
        nickNameTextField.tap()
        nickNameTextField.typeText("Alicia")
        addressTextField.tap()
        addressTextField.typeText("0376f5935fb69361c7a3fbe1c8ce67e034ade3da726a52cf070b63174c853de13f")
        routeHintTextField.tap()
        routeHintTextField.typeText("0343f9e2945b232c5c0e7833acef052d10acf80d1e8a168d86ccb588e63cd962cd_529771090543902727")
        app.buttons["Done"].tap() // Press the "Done" button
        sleep(1)
        
        saveToContactsContainer.tap()
        
        sleep(10)
        let collectionView = app.collectionViews["chatListCollectionView"]
        XCTAssertTrue(collectionView.cells.count == 1)
    }


}
