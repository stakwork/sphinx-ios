//
//  sphinxOnionAccountCreateUITests.swift
//  sphinxUITests
//
//  Created by James Carucci on 11/20/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import XCTest

final class sphinxOnionAccountCreateUITests: XCTestCase {
    
    private var app : XCUIApplication!
    let test_mnemonic1 = "artist globe myself huge wing drive bright build agree fork media gentle"
    
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
        //TODO: find solution for resetting everything
        //UserData.sharedInstance.clearData()
    }


//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
    
    func test_fresh_launch_initial_user_welcome_UI() throws {
        // Launch the app

        // Find the buttons by their accessibility identifiers
        let newUserButton = app.buttons["new.user"]
        let existingUserButton = app.buttons["existing.user"]

        // Verify that the buttons exist
        XCTAssertTrue(newUserButton.exists)
        XCTAssertTrue(existingUserButton.exists)

        // Verify the labels on the buttons
        XCTAssertEqual(newUserButton.label, "New user")
        XCTAssertEqual(existingUserButton.label, "Existing user")
    }
    
    func test_fresh_launch_new_user_UI() throws {
        

        // Find the buttons by their accessibility identifiers
        let newUserButton = app.buttons["new.user"]

        // Verify that the buttons exist
        newUserButton.tap()
        
        let connectionCodeButton = app.buttons["signup.signup-options.connection-code-button"]
        let buyALiteNodeButton = app.buttons["signup.signup-options.lite-node-button"]
        
        XCTAssertTrue(buyALiteNodeButton.exists)
        XCTAssertTrue(connectionCodeButton.exists)
        
        XCTAssertEqual(connectionCodeButton.label, "I Have a Connection Code")
        XCTAssertEqual(buyALiteNodeButton.label, "Buy A Lite Node ($2.99)")
    }
    
    func test_fresh_launch_qr_code_instructions_UI() throws {
        

        // Find the buttons by their accessibility identifiers
        let newUserButton = app.buttons["new.user"]

        // Verify that the buttons exist
        newUserButton.tap()
        sleep(2)
        
        let connectionCodeButton = app.buttons["signup.signup-options.connection-code-button"]
        connectionCodeButton.tap()
        
        let continueButton = app.buttons["signup.description.continue"]
        
        XCTAssertTrue(continueButton.exists)
        
        XCTAssertEqual(continueButton.label, "Continue")
    }
    
    func test_fresh_launch_test_server_connection_UI() throws {
        

        // Find the buttons by their accessibility identifiers
        let newUserButton = app.buttons["new.user"]

        // Verify that the buttons exist
        newUserButton.tap()
        sleep(2)
        
        let connectionCodeButton = app.buttons["signup.signup-options.connection-code-button"]
        connectionCodeButton.tap()
        sleep(2)
        
        let continueButton = app.buttons["signup.description.continue"]
        continueButton.tap()
        sleep(2)
        
        let label = "Connect to Test Server"
        let connectToTestServerButton = app.buttons[label]
        
        let submitButton = app.buttons["submit"]
        
        XCTAssertEqual(connectToTestServerButton.label, label)
        XCTAssertEqual(submitButton.label, "Submit")
    }
    
    func test_fresh_launch_test_v2_flow_generate_copy_complete_sign_up_UI() throws {
        // Find the buttons by their accessibility identifiers
        let newUserButton = app.buttons["new.user"]

        // Verify that the buttons exist
        newUserButton.tap()
        sleep(2)
        
        let connectionCodeButton = app.buttons["signup.signup-options.connection-code-button"]
        connectionCodeButton.tap()
        sleep(2)
        
        let continueButton = app.buttons["signup.description.continue"]
        continueButton.tap()
        sleep(2)
        
        let label = "Connect to Test Server"
        let connectToTestServerButton = app.buttons[label]
        connectToTestServerButton.tap()
        sleep(2)
        
        validateGenerateSeedUI()
        
        validateAndPerformCopySeedAction()
        
        completeAndValidatePostSeedInputSignupFlow()
    }
    
    func test_fresh_launch_test_v2_flow_import_press_ok_complete_sign_up_UI(importedApp:XCUIApplication? = nil) throws {
        if(importedApp != nil){
            app = importedApp
        }
        // Find the buttons by their accessibility identifiers
        let newUserButton = app.buttons["new.user"]

        // Verify that the buttons exist
        newUserButton.tap()
        sleep(2)
        
        let connectionCodeButton = app.buttons["signup.signup-options.connection-code-button"]
        connectionCodeButton.tap()
        sleep(2)
        
        let continueButton = app.buttons["signup.description.continue"]
        continueButton.tap()
        sleep(2)
        
        let label = "Connect to Test Server"
        let connectToTestServerButton = app.buttons[label]
        connectToTestServerButton.tap()
        sleep(2)
        
        validateImportSeed()
        
        sleep(15)
        
        completeAndValidatePostSeedInputSignupFlow()
    }
    
    func validateImportSeed(){
        let alerts = app.alerts
        print(alerts)
        let alert = app.alerts["Choose Your Seed Method"]
        let importButton = alert.buttons["Import"]
        
        // Validate the existence of the alert
        XCTAssertTrue(alert.exists)
        XCTAssertTrue(importButton.exists)
        
        importButton.tap()
        sleep(2)
        
        let importView = app.otherElements["importSeedView"]
        let importSeedViewTextView = app.textViews["importSeedView.textView"]
        let confirmButton =  app.buttons["importSeedView.confirmButton"]
        let cancelButton =  app.buttons["importSeedView.cancelButton"]
        XCTAssertTrue(importView.exists)
        XCTAssertTrue(importSeedViewTextView.exists)
        XCTAssertTrue(confirmButton.exists)
        XCTAssertTrue(cancelButton.exists)
        
        importSeedViewTextView.tap()
        importSeedViewTextView.typeText(test_mnemonic1)
        sleep(1)
        confirmButton.tap()
    }
    
    func validateGenerateSeedUI(){
        let alerts = app.alerts
        print(alerts)
        let alert = app.alerts["Choose Your Seed Method"]
        let generateButton = alert.buttons["Generate"]
        
        // Validate the existence of the alert
        XCTAssertTrue(alert.exists)
        XCTAssertTrue(generateButton.exists)
        
        generateButton.tap()
        sleep(2)
    }
    
    func validateAndPerformOkSeedAction(){
        let secondAlert = app.alerts["Store your Mnemonic securely"]
        let okButton = secondAlert.buttons["Ok"]
        
        XCTAssertTrue(secondAlert.exists)
        XCTAssertTrue(okButton.exists)
        okButton.tap()
        sleep(15)
    }
    
    func validateAndPerformCopySeedAction(){
        let secondAlert = app.alerts["Store your Mnemonic securely"]
        let copyButton = secondAlert.buttons["Copy"]
        
        XCTAssertTrue(secondAlert.exists)
        XCTAssertTrue(copyButton.exists)
        copyButton.tap()
        let clipboard = UIPasteboard.general
        let clipboardContents = clipboard.string
        XCTAssertTrue(clipboardContents?.split(separator: " ").count == 12)
        sleep(15)
    }
    
    func completeAndValidatePostSeedInputSignupFlow(){
        let nextButton = app.buttons["getStartedNextButton"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        sleep(1)
        
        let pinButton1 = app.buttons["keyPadButton-1"]
        for i in 1..<10{
            let pinButton = app.buttons["keyPadButton-\(i)"]
            XCTAssertTrue(pinButton.exists)
        }
        XCTAssertTrue(pinButton1.exists)
        
        let requiredNumTaps = 12
        for _ in 0..<(requiredNumTaps){
            usleep(useconds_t(500e3))
            if(pinButton1.exists){
                pinButton1.tap()
            }
        }
        sleep(2)
        
        let continueButton2 = app.buttons["continueButton"]
        XCTAssertTrue(continueButton2.exists)
        continueButton2.tap()
        sleep(2)
        
        let nextButton2 = app.buttons["nextButton"]
        let nicknameTextfield = app.textFields["nicknameTextField"]
        
        XCTAssertTrue(nicknameTextfield.exists)
        nicknameTextfield.tap()
        nicknameTextfield.typeText("John Doe")
        app.buttons["Done"].tap() // Press the "Done" button
        sleep(3)
        XCTAssertTrue(nextButton2.exists)
        nextButton2.tap()
        sleep(3)
        
        let skipButton = app.buttons["nextOrSkipButton"]
        XCTAssertTrue(skipButton.exists)
        skipButton.tap()
        sleep(2)
        
        let skipButton2 = app.buttons["skipButtonView"]
        XCTAssertTrue(skipButton2.exists)
        XCTAssertEqual(skipButton2.label, "Skip")
        skipButton2.tap()
        sleep(2)
        
        let finishButton = app.buttons["finishButton"]
        finishButton.tap()
        sleep(8)
        
        validateDashboardView()
    }
    
    func validateDashboardView(){
        XCTAssertTrue(app.otherElements["bottomBar"].exists)
        XCTAssertTrue(app.otherElements["bottomBarContainer"].exists)
        XCTAssertTrue(app.otherElements["headerView"].exists)
        XCTAssertTrue(app.otherElements["searchBar"].exists)
        XCTAssertTrue(app.otherElements["searchBarContainer"].exists)
        XCTAssertTrue(app.otherElements["mainContentContainerView"].exists)
    }

}


