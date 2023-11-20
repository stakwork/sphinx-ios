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
    
    func test_fresh_launch_test_v2_generate_then_username_UI() throws {
        

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
        
        let alerts = app.alerts
        print(alerts)
        let alert = app.alerts["Choose Your Seed Method"]
        let generateButton = alert.buttons["Generate"]
        
        // Validate the existence of the alert
        XCTAssertTrue(alert.exists)
        XCTAssertTrue(generateButton.exists)
        
        generateButton.tap()
        sleep(2)
        
        let secondAlert = app.alerts["Store your Mnemonic securely"]
        let copyButton = secondAlert.buttons["Copy"]
        
        XCTAssertTrue(secondAlert.exists)
        XCTAssertTrue(copyButton.exists)
        copyButton.tap()
        sleep(15)
        
        let nextButton = app.buttons["getStartedNextButton"]
        nextButton.tap()
        sleep(1)
        
        let pinButton1 = app.buttons["keyPadButton-1"]
        XCTAssertTrue(pinButton1.exists)
        
        let requiredNumTaps = 12
        for _ in 0..<(requiredNumTaps + 1){
            pinButton1.tap()
        }
    }

}


