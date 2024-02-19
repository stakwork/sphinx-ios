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
import SwiftyJSON
@testable import sphinx


func sendRemoteServerMessageRequest(pubkey: String, theMsg: String, amount:Int=0) {
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

func requestListenForIncomingMessage(completion: @escaping (JSON) -> ()) {
    let url = "http://localhost:4020/arm"
    let parameters: [String: Any] = [:]
    
    AF.request(url, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        switch response.result {
        case .success(let data):
            let json = JSON(data)
            print("Response: \(json)")
            completion(json)
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
    
    func enforceDelay(delay: TimeInterval) {
        let expectation3 = XCTestExpectation(description: "Expecting to have retrieved message in time")
        fulfillExpectationAfterDelay(expectation: expectation3, delayInSeconds: delay)
        // Wait for the expectation to be fulfilled.
        wait(for: [expectation3], timeout: delay + 1.0)
    }
    
    func establish_test_contact() {
        // Assuming `makeFriendRequest` and the existence of `test_contact_info` and `self_alias` are correct as provided
        sphinxOnionManager.mqtt.didReceiveMessage = { mqtt, receivedMessage, id in
            self.sphinxOnionManager.processMqttMessages(message: receivedMessage)
        }
        sphinxOnionManager.makeFriendRequest(contactInfo: test_contact_info, nickname: self_alias)
        let myUserId = UserData.sharedInstance.getUserId()
        
        
        guard let contact = UserContact.getContactWithDisregardStatus(pubkey: self.test_sender_pubkey) else{
            return
        }
        
        let expectation = XCTestExpectation(description: "Expecting to have established self contact in this time.")
        enforceDelay(delay: 8.0)
        
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
        chat.name = self.self_alias
        
        // Save the context
        self.sphinxOnionManager.managedContext.saveContext()
    }

    
    func fulfillExpectationAfterDelay(expectation: XCTestExpectation, delayInSeconds delay: TimeInterval) {
        // Dispatch after the specified delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Fulfill the expectation
            expectation.fulfill()
        }
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        UserData.sharedInstance.save(walletMnemonic: test_mnemonic2)
        
//        establish_self_contact()
//        let expectation = XCTestExpectation(description: "Expecting to have established self contact in this time.")
//        enforceDelay(expectation: expectation, delay: 8.0)
//        establish_test_contact()
//        let expectation2 = XCTestExpectation(description: "Expecting to have established test contact in this time.")
//        enforceDelay(expectation: expectation2, delay: 45.0)
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
            "alias": message.senderAlias?.lowercased() ?? ""
        ]
    }

    //MARK: Type 0 Messages:
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
        sendRemoteServerMessageRequest(pubkey: pubkey, theMsg: "\(test_received_message_content)")
        enforceDelay(delay: 8.0)
        
        //4. Confirm that the known message content matches what we expect
        let contacts = sphinxOnionManager.listContacts()
        print(contacts)
        XCTAssertTrue(receivedMessage != nil)
        XCTAssertTrue(receivedMessage?["content"] as? String == test_received_message_content)
        XCTAssertTrue(receivedMessage?["alias"] as? String == "alice")
        //XCTAssert(receivedMessage?["senderPubkey"] as? String == test_sender_pubkey)
        
    }
    
    
    
    func test_send_plaintext_message() throws {
        let expectation = XCTestExpectation(description: "Expecting to have retrieved message in time")
        enforceDelay(delay: 8.0)
        //2. Send message with random content
        guard let rand = CrypterManager().generateCryptographicallySecureRandomInt(upperBound: 100_000_000) else{
            XCTFail()
            return
        }
        let content = String(describing: rand)
        
        guard let contact = UserContact.getContactWithDisregardStatus(pubkey: test_sender_pubkey),
            let chat = contact.getChat() else{
            XCTFail("Failed to establish self contact")
            return
        }
        var messageResult : JSON? = nil
        requestListenForIncomingMessage(completion: {result in
            messageResult = result
        })
        let expectation2 = XCTestExpectation(description: "Expecting to have retrieved message in time")
        enforceDelay(delay: 8.0)
        
        sphinxOnionManager.sendMessage(to: contact, content: content, chat: chat, amount: 0, shouldSendAsKeysend: false, msgType: 0, muid: nil, recipPubkey: nil, mediaKey: nil, mediaType: nil, threadUUID: nil, replyUUID: nil)
        
        let expectation3 = XCTestExpectation(description: "Expecting to have retrieved message in time")
        enforceDelay( delay: 14.0)
        guard let resultDict = messageResult?.dictionaryValue,
              let dataDict = resultDict["data"]?.dictionaryValue,
                let msg = dataDict["msg"]?.rawString() else{
            XCTFail("Value coming back is invalid")
            return
        }
        for key in dataDict.keys{
            print("key:\(key), value:\(dataDict[key])")
        }
        
        let contentMatch = msg.contains(content)
        XCTAssert(contentMatch == true)
        
        print(messageResult)
        
        //let stringContent = String(content)
        
        //sphinxOnionManager.sendMessage(to: contact, content: stringContent)
        
        //3. Await ACK message
        
        //4. Ensure ACK message reflects same message we sent out.
    }
    
    //MARK: Type 6 Attachment Messages
    func test_send_attachment_message() throws {
        let expectation = XCTestExpectation(description: "Expecting to have retrieved message in time")
        enforceDelay(delay: 8.0)
        //2. Send message with random content
        guard let rand = CrypterManager().generateCryptographicallySecureRandomInt(upperBound: 100_000_000) else{
            XCTFail()
            return
        }
        let content = String(describing: rand)
        
        guard let contact = UserContact.getContactWithDisregardStatus(pubkey: test_sender_pubkey),
            let chat = contact.getChat() else{
            XCTFail("Failed to establish self contact")
            return
        }
        var messageResult : JSON? = nil
        requestListenForIncomingMessage(completion: {result in
            messageResult = result
        })
        let expectation2 = XCTestExpectation(description: "Expecting to have retrieved message in time")
        enforceDelay(delay: 8.0)
        
        let fakeFile: NSDictionary = [
            "description": "description",
            "template": 0,
            "updated": "2024-02-19T15:45:51.088669581Z",
            "ttl": 31536000,
            "filename": "image.jpg",
            "mime": "image/jpg",
            "tags": [],
            "width": 0,
            "owner_pub_key": "Al-nkDa5wmTQJNOPP9z49R7Jja3D9HPn1ofNNSqOEoRX",
            "size": 500674,
            "price": 0,
            "muid": "nIGa243jKrQP4vkOMU-ub0ZS4di8paVR9FSmxx9MYBs=",
            "created": "2024-02-19T15:45:51.088669581Z",
            "expiry": "2025-02-19T15:45:51.088669581Z",
            "height": 0,
            "name": "image"
        ]
        
        let exampleData = Data(count: 500674) // Replace with actual data
        let exampleImage = UIImage() // Replace with actual UIImage
        let testMediaKey = "Njc0MTZCMEZBNDAzNEMzNzk4RDczMDFD"
        // Creating the AttachmentObject instance
        var attachmentObject = AttachmentObject(
            data: exampleData,
            mediaKey: testMediaKey,
            type: .Photo,
            image: exampleImage,
            contactPubkey: "023be900c195aee419e5f68bf4b7bc156597da7649a9103b1afec949d233e4d1aa"
        )

        attachmentObject.text = content
        guard let sentMessage = sphinxOnionManager.sendAttachment(file: fakeFile, attachmentObject: attachmentObject, chat: chat, replyingMessage: nil, threadUUID: nil),
              let testMediaToken = sentMessage.mediaToken else{
            XCTFail("Expected to get back valid pre-flight message")
            return
        }
        
        
        
        let expectation3 = XCTestExpectation(description: "Expecting to have retrieved message in time")
        enforceDelay( delay: 14.0)
        
        //Example result for reference:
//        => msg type: attachment
//        => msg {"content":"","mediaToken":"bWVtZXMuc3BoaW54LmNoYXQ=.M_ZcxtcbRUZmDcHDYahSDvZJV4eOFvapZOb2wa-qNy0=..Z7X6KA==..ILxohNjxscIumj0f5NH1fySoR1HirySwMEHwVTGCAqzgPxXINtIyVO4agyf12hulTvCLDbKyOatmdotD9TBqLD4=","mediaKey":"Q0QxQjUyMkMzODM3NDE2NTg1NDgxQTBD","mediaType":"image/jpg","date":2182593930}
//        => sender {"pubkey":"025fa79036b9c264d024d38f3fdcf8f51ec98dadc3f473e7d687cd352a8e128457","alias":"ALICE","photo_url":"","person":"","confirmed":true}
//        => msat 0n
//        => uuid fe278dc86e968281ad368f5586243ce682045013cdca85aa8b9c8c9838e60b11
//        => index 155
        guard let resultDict = messageResult?.dictionaryValue,
              let dataDict = resultDict["data"]?.dictionaryValue,
                let msg = dataDict["msg"]?.rawString() else{
            XCTFail("Value coming back is invalid")
            return
        }
        for key in dataDict.keys{
            print("key:\(key), value:\(dataDict[key])")
        }
        
        let contentMatch = msg.contains(content)
        XCTAssert(contentMatch == true)
        let mediaKeyMatch = msg.contains(testMediaKey)
        XCTAssert(mediaKeyMatch == true)
        let mediaTokenMatch = msg.contains(testMediaToken)
        XCTAssert(mediaTokenMatch == true)
        
        print(messageResult)
        
        //let stringContent = String(content)
        
        //sphinxOnionManager.sendMessage(to: contact, content: stringContent)
        
        //3. Await ACK message
        
        //4. Ensure ACK message reflects same message we sent out.
    }
}
