//
//  sphinxOnionPlaintextMessagesTests.swift
//  sphinxTests
//
//  Created by James Carucci on 12/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

//Test Regime 3 - Messaging

import XCTest
import Alamofire
@testable import sphinx


func performRemoteServerAction(pubkey: String, theMsg: String, amount:Int=0) {
    let url = "http://localhost:4020/command"
    let parameters: [String: Any] = [
        "command": "send",
        "parameters": [
            pubkey,
            amount,
            theMsg
        ]
    ]
    
    AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        switch response.result {
        case .success(let value):
            print("Response: \(value)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}

final class sphinxOnionPlaintextMessagesTests: XCTestCase {
    let sphinxOnionManager = SphinxOnionManager.sharedInstance
    //Account details for test account aka David
    let test_mnemonic2 = "embody correct zebra nephew elevator anchor page remind silk fog immune fitness"
    
    var receivedMessage : [String:Any]? = nil
    let test_sender_pubkey = "023be900c195aee419e5f68bf4b7bc156597da7649a9103b1afec949d233e4d1aa"
    let test_contact_info = "023be900c195aee419e5f68bf4b7bc156597da7649a9103b1afec949d233e4d1aa_02adccd7f574d17d627541b447f47493916e78e33c1583ba9936607b35ca99c392_529771090670583808"
    var test_received_message_content = "Sphinx_is_awesome"
    let self_alias = "satoshi"
    
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
        
        //subscribe to relevant topics
        sphinxOnionManager.mqtt.didConnectAck = { _, _ in
            //self.showSuccessWithMessage("MQTT connected")
            print("SphinxOnionManager: MQTT Connected")
            print("mqtt.didConnectAck")
            self.sphinxOnionManager.subscribeAndPublishMyTopics(pubkey: pubkey, idx: 0)
            //self.sphinxOnionManager.getUnreadOkKeyMessages(sinceIndex: 1, limit: 1)
        }

    }
    
    func establish_test_contact() {
        // Assuming `makeFriendRequest` and the existence of `test_contact_info` and `self_alias` are correct as provided
        sphinxOnionManager.makeFriendRequest(contactInfo: test_contact_info, nickname: self_alias)
        let myUserId = UserData.sharedInstance.getUserId()
        DelayPerformedHelper.performAfterDelay(seconds: 5.0, completion: {
            guard let contact = UserContact.getContactWithDisregardStatus(pubkey: self.test_sender_pubkey) else{
                return
            }
            // Assuming `sphinxOnionManager.managedContext` is a valid NSManagedObjectContext
            let chat = Chat(context: self.sphinxOnionManager.managedContext)
            
            // Set mandatory fields with neutral values
            chat.id = 21 // Provided as an example, assuming this is mandatory and unique for each chat
            chat.type = 0 // Assuming '0' is a neutral/placeholder value for type
            chat.status = 0 // Assuming '0' is a neutral/placeholder value for status
            chat.createdAt = Date() // Sets to current date and time
            chat.muted = false // Assuming 'false' as a neutral value for muted
            chat.seen = false // Assuming 'false' as a neutral value for seen
            chat.unlisted = false // Assuming 'false' as a neutral value for unlisted
            chat.privateTribe = false // Assuming 'false' as a neutral value for privateTribe
            chat.notify = 0 // Assuming '0' as a neutral/placeholder value for notify
            chat.isTribeICreated = false // Assuming 'false' as a neutral value for isTribeICreated
            chat.contactIds = [NSNumber(integerLiteral: myUserId),NSNumber(integerLiteral: contact.id)] // Assuming an empty array as a neutral value
            chat.pendingContactIds = [] // Assuming an empty array as a neutral value
            
            // Set the ownerPubkey if it's considered mandatory
            chat.ownerPubkey = self.test_sender_pubkey // Use a test or neutral public key value
            
            // Save the context
            self.sphinxOnionManager.managedContext.saveContext()
        })
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
        let expectation = XCTestExpectation(description: "Expecting to have established self contact in this time.")
        fulfillExpectationAfterDelay(expectation, delayInSeconds: 8.0)
        // Wait for the expectation to be fulfilled.
        wait(for: [expectation], timeout: 10.0)
        establish_test_contact()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    //inspect incoming messages
    @objc func handleNewOnionMessageReceived(n:Notification){
        
        guard let message = n.userInfo?["message"] as? TransactionMessage else{
              return
          }
        
        receivedMessage = [
            "content": message.messageContent ?? "",
            "senderPubkey":message.chat?.getChat()?.ownerPubkey ?? ""
        ]
    }

    func test_receive_plaintext_message() throws {
        //0. Set up test client running on http://localhost:4020 from Sphinx repo
        //1. Listen to the correct channels -> handled in setup
        
        //2. Publish to a channel known to contain a message
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewOnionMessageReceived), name: .newOnionMessageWasReceived, object: nil)
        
        guard let profile = UserContact.getOwner(),
              let pubkey = profile.publicKey else{
            XCTFail("Failed to establish self contact")
            return
        }
        
        //3. Await results to come in
        test_received_message_content += "-\(sphinxOnionManager.getEntropyString())"//Guarantee unique string each time
        performRemoteServerAction(pubkey: pubkey, theMsg: "\(test_received_message_content)")
        let expectation = XCTestExpectation(description: "Expecting to have retrieved message in time")
        fulfillExpectationAfterDelay(expectation, delayInSeconds: 18.0)
        // Wait for the expectation to be fulfilled.
        wait(for: [expectation], timeout: 20.0)
        
        //4. Confirm that the known message content matches what we expect
        
        XCTAssertTrue(receivedMessage != nil)
        XCTAssertTrue(receivedMessage?["content"] as? String == test_received_message_content)
        XCTAssert(receivedMessage?["senderPubkey"] as? String == test_sender_pubkey)
        
    }
    
    func test_send_plaintext_message() throws {
        //1. Establish self contact and set up "sock puppet" account over http making sure it will mirror our message through an ACK
        
        //setUpMirrorSockPuppet(seed: , pubkey: )
        
        //2. Send message with random content
        let content = CrypterManager().generateCryptographicallySecureRandomInt(upperBound: 100_000_000)
        //let stringContent = String(content)
        
        //sphinxOnionManager.sendMessage(to: contact, content: stringContent)
        
        //3. Await ACK message
        
        //4. Ensure ACK message reflects same message we sent out.
    }

}
