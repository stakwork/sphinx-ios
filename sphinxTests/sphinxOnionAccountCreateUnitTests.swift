//
//  sphinxOnionAccountCreateUnitTests.swift
//  sphinxTests
//
//  Created by James Carucci on 11/20/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import XCTest
@testable import sphinx

class sphinxOnionAccountCreateUnitTests: XCTestCase {
    var sphinxOnionManager = SphinxOnionManager.sharedInstance
    let test_mnemonic1 = "artist globe myself huge wing drive bright build agree fork media gentle"
    let test_mnemonic1_expected_seed = "dea65b969cd1b0926889f35699586ff7e19469c64e7a944d0c6b68342158a1a8"
    let test_mnemonic1_expected_okKey = "02c24c838266d07cbde76642e08a62a4b5c750e3ba318a9fbbf97f8ec0ff66b134"
    let test_mnemonic1_expected_xpub = "tpubDAGRb7j9yEF51RrPBjxYk6inEyxzX9oZEqRfWGGtnhEaux2xsma2eQFNBYeRgEHLC5pc4Cif4KPJXXRqS1aTErvhvTiZGaGggq9UoTZdEsH"
    let test_server_ip = "34.229.52.200"
    let test_server_pubkey = "0343f9e2945b232c5c0e7833acef052d10acf80d1e8a168d86ccb588e63cd962cd"
    
    var server : Server? = nil
    var balance: String? = nil
    var expectation: XCTestExpectation?
    
    func handleServerNotification(n: Notification) {
        if let server = n.userInfo?["server"] as? Server{
            self.server = server
            self.expectation?.fulfill()
        }
    }
    
    func handleBalanceNotification(n:Notification){
        if let balance = n.userInfo?["balance"] as? String{
            self.balance = balance
            self.expectation?.fulfill()
        }
    }
    
    func validateServerParams()->Bool{
        guard let server = server else{
            return false
        }
        return server.ip == test_server_ip && server.pubKey == test_server_pubkey
    }
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        server = nil
    }

    func test_seed_generation(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1) else{
            XCTFail("Key generation has failed (test_seed_generation)")
            return
        }
        XCTAssert(seed == test_mnemonic1_expected_seed)
    }
    
    func test_ok_key_generation(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let ok_key = sphinxOnionManager.getAccountOnlyKeysendPubkey(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_ok_key_generation)")
            return
      }
        XCTAssert(ok_key == test_mnemonic1_expected_okKey)
    }
    
    func test_xpub_generation(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let xpub = sphinxOnionManager.getAccountXpub(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_ok_key_generation)")
            return
      }
        XCTAssert(xpub == test_mnemonic1_expected_xpub)
    }
    
    func test_connect_to_mqtt_broker(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let xpub = sphinxOnionManager.getAccountXpub(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_connect_to_mqtt_broker)")
            return
      }
        let success = sphinxOnionManager.connectToBroker(seed: seed, xpub: xpub)
        XCTAssert(success == true, "Failed to connect to test broker :/")
    }
    
    //MARK: Punting until we have more clarity on this
//    func test_mqtt_server_broker_registration(){
//        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
//          let xpub = sphinxOnionManager.getAccountXpub(seed: seed),
//        let pubkey = sphinxOnionManager.getAccountOnlyKeysendPubkey(seed: seed) else{
//              XCTFail("failure to properly generate seed & then ok key (test_connect_to_mqtt_broker)")
//            return
//      }
//        sphinxOnionManager.shouldPostUpdates = true
//        NotificationCenter.default.addObserver(self, selector: #selector(handleServerNotification), name: .onMQTTConnectionStatusChanged, object: nil)
//        
//        let success = sphinxOnionManager.connectToBroker(seed: seed, xpub: xpub)
//        XCTAssert(success == true, "Failed to connect to test broker :/")
//        
//        sphinxOnionManager.mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
//            self.sphinxOnionManager.processMqttMessages(message: receivedMessage)
//        }
//        
//        //subscribe to relevant topics
//        sphinxOnionManager.mqtt.didConnectAck = { _, _ in
//            //self.showSuccessWithMessage("MQTT connected")
//            print("SphinxOnionManager: MQTT Connected")
//            print("mqtt.didConnectAck")
//            self.sphinxOnionManager.subscribeAndPublishMyTopics(pubkey: pubkey, idx: 0)
//        }
//        
//        expectation = self.expectation(description: "Server should send back valid params within 10 seconds")
//        waitForExpectations(timeout: 10) { error in
//            if let error = error {
//                XCTFail("Timeout: \(error)")
//            }
//            
//            // After the expectation is fulfilled, you can check your variable
//            XCTAssert(self.validateServerParams() == true)
//        }
//    }
    
    //MARK: Punt until we know that we will get valid responses from the server on this...
//    func test_mqtt_server_broker_get_balance(){
//        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
//          let xpub = sphinxOnionManager.getAccountXpub(seed: seed),
//        let pubkey = sphinxOnionManager.getAccountOnlyKeysendPubkey(seed: seed) else{
//              XCTFail("failure to properly generate seed & then ok key (test_connect_to_mqtt_broker)")
//            return
//      }
//        sphinxOnionManager.shouldPostUpdates = true
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleBalanceNotification), name: .onBalanceDidChange, object: nil)
//        
//        let success = sphinxOnionManager.connectToBroker(seed: seed, xpub: xpub)
//        XCTAssert(success == true, "Failed to connect to test broker :/")
//        
//        sphinxOnionManager.mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
//            self.sphinxOnionManager.processMqttMessages(message: receivedMessage)
//        }
//        
//        //subscribe to relevant topics
//        sphinxOnionManager.mqtt.didConnectAck = { _, _ in
//            //self.showSuccessWithMessage("MQTT connected")
//            print("SphinxOnionManager: MQTT Connected")
//            print("mqtt.didConnectAck")
//            self.sphinxOnionManager.subscribeAndPublishMyTopics(pubkey: pubkey, idx: 0)
//        }
//        
//        expectation = self.expectation(description: "Server should send back valid balance within 10 seconds")
//        waitForExpectations(timeout: 10) { error in
//            if let error = error {
//                XCTFail("Timeout: \(error)")
//            }
//            
//            // After the expectation is fulfilled, you can check your variable
//            XCTAssert(self.balance == "0")
//        }
//    }

}
