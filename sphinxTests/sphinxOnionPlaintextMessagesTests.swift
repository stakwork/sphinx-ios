//
//  sphinxOnionPlaintextMessagesTests.swift
//  sphinxTests
//
//  Created by James Carucci on 12/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import XCTest
@testable import sphinx

final class sphinxOnionPlaintextMessagesTests: XCTestCase {
    let sphinxOnionManager = SphinxOnionManager.sharedInstance
    //Account details for test account aka Zoe
    let test_mnemonic2 = "scare eternal practice consider jaguar orient coach weekend ladder aware regular bike"
    let test_route_hint = "0286427d130ef4289731529225da41733bb2accd0b976c9e3f96353e1bce555191"
    let test_pubkey = "038e286f590b9ef87e367294adfdaa105dc1bcd832201d440a3b84275f3dbb6b13_529771090679103495"
    let expected_test_message_received_content = "Sphinx is awesome."
    
    //Mnemonic for "heel" account that helps test: post captain sister quit hurt stadium brand leopard air give funny begin
    
    
    func establish_self_contact(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic2),
          let xpub = sphinxOnionManager.getAccountXpub(seed: seed),
        let pubkey = sphinxOnionManager.getAccountOnlyKeysendPubkey(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_connect_to_mqtt_broker)")
            return
      }
        
        let success = sphinxOnionManager.connectToBroker(seed: seed, xpub: xpub)
        XCTAssert(success == true, "Failed to connect to test broker :/")
        
        sphinxOnionManager.mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
            self.sphinxOnionManager.processMqttMessages(message: receivedMessage)
        }
        
        //subscribe to relevant topics
        sphinxOnionManager.mqtt.didConnectAck = { _, _ in
            //self.showSuccessWithMessage("MQTT connected")
            print("SphinxOnionManager: MQTT Connected")
            print("mqtt.didConnectAck")
            self.sphinxOnionManager.subscribeAndPublishMyTopics(pubkey: pubkey, idx: 0)
        }

    }
    
    func fulfillExpectationAfterDelay(_ expectation: XCTestExpectation, delayInSeconds: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: delayInSeconds, repeats: false) { _ in
            expectation.fulfill()
        }
        // Make sure the timer is added to the current run loop to start counting down.
        RunLoop.current.add(timer, forMode: .common)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        establish_self_contact()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    

    func test_receive_plaintext_message() throws {
        //1. Listen to the correct channels
        
        sphinxOnionManager.getUnreadOkKeyMessages()
        
        let expectation = XCTestExpectation(description: "Expecting to have retrieved message in time")
        fulfillExpectationAfterDelay(expectation, delayInSeconds: 15.0)
        // Wait for the expectation to be fulfilled.
        wait(for: [expectation], timeout: 20.0)
        XCTAssert(true)
        
        //2. Publish to a channel known to contain a message
        
        //3. Await results to come in
        
        //4. Confirm that the known message content matches what we expect
    }
    
    func test_send_plaintext_message() throws {
        
    }

}
