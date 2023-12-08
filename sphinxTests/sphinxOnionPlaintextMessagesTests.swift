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
    //Account details for test account aka David
    let test_mnemonic2 = "embody correct zebra nephew elevator anchor page remind silk fog immune fitness"
    
    var receivedMessage : [String:Any]? = nil
    let test_sender_pubkey = "02b81cdabc6de419b7b582418640da1f322310fd0c30acb1e19c2fe35b13b08ceb"
    let test_received_message_content = "testtesttest"
    
    //Mnemonic for "sock puppet" account that helps test: post captain sister quit hurt stadium brand leopard air give funny begin
    
    
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
            self.sphinxOnionManager.getUnreadOkKeyMessages(sinceIndex: 1, limit: 1)
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
        UserData.sharedInstance.save(walletMnemonic: test_mnemonic2)
        establish_self_contact()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    //inspect incoming messages
    @objc func handleNewOnionMessageReceived(n:Notification){
        
        guard let messageDict = n.userInfo?["messageDict"] as? [String:Any],
              let message = messageDict["message"] as? [String:String],
            let content = message["content"],
            let sender = messageDict["sender"] as? [String:String],
            let pubkey = sender["pubkey"] else{
              return
          }
        
        receivedMessage = [
            "content": content,
            "senderPubkey":pubkey
        ]
        print("content:\(content)")
    }

    func test_receive_plaintext_message() throws {
        //1. Listen to the correct channels -> handled in setup
        
        //2. Publish to a channel known to contain a message
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewOnionMessageReceived), name: .newOnionMessageWasReceived, object: nil)
        
        //3. Await results to come in
        
        let expectation = XCTestExpectation(description: "Expecting to have retrieved message in time")
        fulfillExpectationAfterDelay(expectation, delayInSeconds: 8.0)
        // Wait for the expectation to be fulfilled.
        wait(for: [expectation], timeout: 10.0)
        
        //4. Confirm that the known message content matches what we expect
        
        XCTAssertTrue(receivedMessage != nil)
        XCTAssertTrue(receivedMessage?["content"] as? String == test_received_message_content)
        XCTAssert(receivedMessage?["senderPubkey"] as? String == test_sender_pubkey)
        
    }
    
    func test_send_plaintext_message() throws {
        //1. Establish self contact and set up "sock puppet" account over http making sure it will mirror our message through an ACK
        
        //2.
    }

}
