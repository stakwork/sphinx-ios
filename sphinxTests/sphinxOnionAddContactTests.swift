//
//  sphinxTests.swift
//  sphinxTests
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import XCTest
@testable import sphinx


class sphinxOnionAddContactTests: XCTestCase {
    var sphinxOnionManager = SphinxOnionManager.sharedInstance
    let test_mnemonic1 = "artist globe myself huge wing drive bright build agree fork media gentle"
    let test_mnemonic1_expected_seed = "dea65b969cd1b0926889f35699586ff7e19469c64e7a944d0c6b68342158a1a8"
    let test_mnemonic1_expected_okKey = "02c24c838266d07cbde76642e08a62a4b5c750e3ba318a9fbbf97f8ec0ff66b134"
    let test_mnemonic1_expected_xpub = "tpubDAGRb7j9yEF51RrPBjxYk6inEyxzX9oZEqRfWGGtnhEaux2xsma2eQFNBYeRgEHLC5pc4Cif4KPJXXRqS1aTErvhvTiZGaGggq9UoTZdEsH"
    let test_server_ip = "34.229.52.200"
    let test_server_pubkey = "0343f9e2945b232c5c0e7833acef052d10acf80d1e8a168d86ccb588e63cd962cd"
    let test_contact_info = "023be900c195aee419e5f68bf4b7bc156597da7649a9103b1afec949d233e4d1aa_03cc30ae6853992275331ba5a699d8fc9575136c65d6374a9e8330d1546edb3c98_529771090558255111"
    
    //MARK: specific to key exchange
    let test_key_exchange_response_message_json : [String: Any] = [
            "pubkey": "03a898d978e42c9feaa25ca103d70b27a2a83472b3b00cd11bbf2a9b3be14460f4",
            "alias": "anon",
            "contactPubkey": "02949826885589228a72f12734a38e7c9901ab50ed1d49eb935b4bd3da2ec60bae",
            "photo_url": ""
    ]
    
    let test_key_exchange_response_prompt = "IMPORTANT - run the following command from sphinx/wasm/test/cli within the next 60 seconds: yarn cli bob friend alice 03a898d978e42c9feaa25ca103d70b27a2a83472b3b00cd11bbf2a9b3be14460f4_0343f9e2945b232c5c0e7833acef052d10acf80d1e8a168d86ccb588e63cd962cd_529771090671435780"
    
    var server : Server? = nil
    var balance: String? = nil
    var hopsJSON: [[String: String]]? = nil
    var contentJSON: [String:Any]? = nil
    var expectation: XCTestExpectation?
    
    //Test helpers://
    
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
    
    func fulfillExpectationAfterDelay(_ expectation: XCTestExpectation, delayInSeconds: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: delayInSeconds, repeats: false) { _ in
            expectation.fulfill()
        }
        // Make sure the timer is added to the current run loop to start counting down.
        RunLoop.current.add(timer, forMode: .common)
    }
    
    //END Test Helpers
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        UserData.sharedInstance.save(walletMnemonic: test_mnemonic1)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        server = nil
        expectation = nil
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
    
    func establish_self_contact(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let xpub = sphinxOnionManager.getAccountXpub(seed: seed),
        let pubkey = sphinxOnionManager.getAccountOnlyKeysendPubkey(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_connect_to_mqtt_broker)")
            return
      }
        sphinxOnionManager.shouldPostUpdates = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleServerNotification), name: .onMQTTConnectionStatusChanged, object: nil)
        
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
    
//    func test_mqtt_server_broker_registration(){
//        establish_self_contact()
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
//    
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
    
    //MARK: Key exchange related
    
    //prove we properly registered the contact before we get a response from the peer but after we got one from the broker server
    func validate_test_contact_pre_key_exchange(contact:UserContact){
        print(contact)
        let expected_pubkey = "023be900c195aee419e5f68bf4b7bc156597da7649a9103b1afec949d233e4d1aa"
        XCTAssertTrue(expected_pubkey == contact.publicKey)
    }
    
    //prove we got a proper response from the peer and saved it in the database correctly
    func validate_test_contact_post_key_exchange(contact:UserContact){
        validate_test_contact_pre_key_exchange(contact: contact)
    
        let expected_nickname = "alice"
        

        XCTAssertTrue(expected_nickname == contact.nickname ?? "")
    }
    
    //prove handshake with server works correctly and we store the basic data in the database *before* completing the key exchange
    func test_new_contact_pre_key_exchange(){
        UserContact.deleteAll()//set to known wiped out state
        UserData.sharedInstance.save(walletMnemonic: test_mnemonic1)
        
        establish_self_contact()
        // Call the function to fulfill the expectation after a 3-second delay.
        let selfContactRegistrationExpectation = XCTestExpectation(description: "Expecting self contact.")
        fulfillExpectationAfterDelay(selfContactRegistrationExpectation, delayInSeconds: 4.5)
        wait(for: [selfContactRegistrationExpectation], timeout: 5.0)//give self contact time to take
        
        sphinxOnionManager.makeFriendRequest(contactInfo: test_contact_info)
        let newContactRegistrationExpectation = XCTestExpectation(description: "Expecting new contact.")
        fulfillExpectationAfterDelay(newContactRegistrationExpectation, delayInSeconds: 4.5)
        wait(for: [newContactRegistrationExpectation], timeout: 5.0)//give self contact time to take
        //test_mqtt_server_broker_registration() //pre requisite before we do any key exchange is register self contact
        let contactPubkey = sphinxOnionManager.parseContactInfoString(fullContactInfo: test_contact_info)?.0 ?? ""
        
        guard let contact = UserContact.getContactsWith(pubkeys: [contactPubkey]).first else{
            XCTFail("Failed contact registration")
            return
        }
        validate_test_contact_pre_key_exchange(contact: contact)
    }
    
    func test_new_contact_initiation_database_record(){
        UserContact.deleteAll()//set to known wiped out state
        UserData.sharedInstance.save(walletMnemonic: test_mnemonic1)
        let expectation = XCTestExpectation(description: "Expecting to get contact info in time")
        
        let delayTime = 8.0
        
        //Async Tasks:
        establish_self_contact()
        // Call the function to fulfill the expectation after a 3-second delay.
        let selfContactRegistrationExpectation = XCTestExpectation(description: "Expecting self contact.")
        fulfillExpectationAfterDelay(selfContactRegistrationExpectation, delayInSeconds: 4.5)
        wait(for: [selfContactRegistrationExpectation], timeout: 5.0)//give self contact time to take
        
        sphinxOnionManager.makeFriendRequest(contactInfo: test_contact_info)
        
        // Call the function to fulfill the expectation after a 3-second delay.
        fulfillExpectationAfterDelay(expectation, delayInSeconds: delayTime)
        // Wait for the expectation to be fulfilled.
        wait(for: [expectation], timeout: delayTime + 1.0) // Adjust the timeout as needed
        print("\n\n\n\n WARNING: Must run yarn cli alice from inside the wasm tests folder in the Sphinx repo in order to ensure the receiver is online & available to respond with the correct data!")
        guard let contact = UserContact.getAll().filter({$0.isOwner == false}).first else{
            XCTFail("Failed contact registration")
            return
        }
        validate_test_contact_post_key_exchange(contact: contact)
    }
    
    func handleKeyExchangeResponseNotification(n:Notification){
        if let hopsJSON = n.userInfo?["hopsJSON"] as? [[String: String]],
           let contentStringJSON = n.userInfo?["contentStringJSON"] as? [String:Any]{
            self.hopsJSON = hopsJSON
            self.contentJSON = contentStringJSON
        }
    }
    
//    func test_key_exchange_response_message() {
//        print(test_key_exchange_response_prompt)
//        UserContact.deleteAll() // set to known wiped out state
//        UserData.sharedInstance.save(walletMnemonic: test_mnemonic1)
//        
//        let delayTime = 20.0
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyExchangeResponseNotification), name: .newContactWasRegisteredWithServer, object: nil)
//        sphinxOnionManager.shouldPostUpdates = true
//        
//        // Async Tasks:
//        establish_self_contact()
//        
//        // Print prompt after a delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            print("\n\n\n\n\n\n\n\n\n\n\n\n\n\(self.test_key_exchange_response_prompt)")
//        }
//        
//        let expectation = XCTestExpectation(description: "Expecting key exchange after some time")
//        // Set up the expectation here
//        fulfillExpectationAfterDelay(expectation, delayInSeconds: delayTime)
//        
//        wait(for: [expectation], timeout: 20.0)
//        for key in test_key_exchange_response_message_json.keys {
//            guard let expectedValue = test_key_exchange_response_message_json[key],
//                  let actualValue = self.contentJSON?[key] else {
//                XCTFail("Key \(key) not found in one of the dictionaries")
//                continue
//            }
//
//            if let expectedValue = expectedValue as? String, let actualValue = actualValue as? String {
//                XCTAssertTrue(expectedValue == actualValue, "Mismatch for key \(key). Expected Value:\(expectedValue). Actual Value: \(actualValue)")
//            } else if let expectedValue = expectedValue as? [String: String], let actualValue = actualValue as? [String: String] {
//                XCTAssertTrue(expectedValue == actualValue, "Mismatch for key \(key)")
//            } else {
//                XCTFail("Type mismatch for key \(key)")
//            }
//        }
//    }



}
