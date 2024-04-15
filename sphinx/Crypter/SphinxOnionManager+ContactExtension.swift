//
//  SphinxOnionManager+ContactExtension.swift
//  sphinx
//
//  Created by James Carucci on 12/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CocoaMQTT
import ObjectMapper
import SwiftyJSON

extension SphinxOnionManager{//contacts related
    
    //MARK: Contact Add helpers
    func saveLSPServerData(retrievedCredentials:SphinxOnionBrokerResponse){
        let server = Server(context: managedContext)

        server.pubKey = retrievedCredentials.serverPubkey
        server.ip = self.server_IP
        (shouldPostUpdates) ?  NotificationCenter.default.post(Notification(name: .onMQTTConnectionStatusChanged, object: nil, userInfo: ["server" : server])) : ()
        self.currentServer = server
        managedContext.saveContext()
    }
    
    func parseContactInfoString(fullContactInfo:String)->(String,String,String)?{
        let components = fullContactInfo.split(separator: "_").map({String($0)})
        if components.count != 3 {return nil}
        return (components.count == 3) ? (components[0],components[1],components[2]) : nil
    }
    
    func makeFriendRequest(
        contactInfo:String,
        nickname:String?=nil,
        inviteCode:String?=nil
    ){
        guard let (recipientPubkey, recipLspPubkey,scid) = parseContactInfoString(fullContactInfo: contactInfo) else{
            return
        }
        if let existingContact = UserContact.getContactWithDisregardStatus(pubkey: recipientPubkey){
            AlertHelper.showAlert(title: "Error", message: "Contact already exists for \(existingContact.nickname ?? "this contact")")
            return
        }
        
        guard let seed = getAccountSeed(),
              let selfContact = UserContact.getSelfContact()
        else{
            return
        }
        
        do{
            let _ = createNewContact(pubkey: recipientPubkey,nickname: nickname)
            var hexCode : String? = nil
            if let inviteCode = inviteCode{
                hexCode = try! codeFromInvite(inviteQr: inviteCode)
            }
            let rr = try! addContact(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), toPubkey: recipientPubkey, routeHint: "\(recipLspPubkey)_\(scid)", myAlias: (selfContact.nickname ?? nickname) ?? "", myImg: selfContact.avatarUrl ?? "", amtMsat: 1000, inviteCode: hexCode, theirAlias: nickname)
            handleRunReturn(rr: rr)
        }
        catch{
            
        }
        
    }
    
    //MARK: Processes key exchange messages (friend requests) between contacts
    func processKeyExchangeMessages(rr:RunReturn){
        for msg in rr.msgs{
            if let sender = msg.sender,
               let csr = ContactServerResponse(JSONString: sender),
               let senderPubkey = csr.pubkey{
                print(sender)
                let type = msg.type ?? 255
                if type == TransactionMessage.TransactionMessageType.contactKeyConfirmation.rawValue,
                   let pubkey = csr.pubkey// incoming key exchange confirmation
                   { // if contact exists it's a key exchange response from them or it exists already
                    var keyExchangeContact = UserContact.getContactWithDisregardStatus(pubkey: senderPubkey) ?? createNewContact(pubkey: pubkey)
                    guard let keyExchangeContact = keyExchangeContact
                    else{
                        //no existing contact!
                        return
                    }
                    NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactPubkey" : keyExchangeContact.publicKey]))
                    keyExchangeContact.nickname = csr.alias
                    keyExchangeContact.avatarUrl = csr.photoUrl
                    if keyExchangeContact.getChat() == nil{
                        createChat(for: keyExchangeContact)
                    }
                    keyExchangeContact.nickname = csr.alias
                    keyExchangeContact.status = UserContact.Status.Confirmed.rawValue
                    CoreDataManager.sharedManager.saveContext()
                    NotificationCenter.default.post(name: .newOnionMessageWasReceived,object:nil, userInfo: ["message": TransactionMessage()])
                    
                }
                else if type == TransactionMessage.TransactionMessageType.contactKey.rawValue, // incoming key exchange request
                        UserContact.getContactWithDisregardStatus(pubkey: senderPubkey) == nil,//don't respond to requests if already exists
                        let newContactRequest = createNewContact(pubkey: senderPubkey, nickname: csr.alias, photo_url: csr.photoUrl, person: csr.person,code:csr.code){//new contact from a key exchange message
                    NotificationCenter.default.post(Notification(name: .newContactWasRegisteredWithServer, object: nil, userInfo: ["contactPubkey" : newContactRequest.publicKey]))
                    newContactRequest.status = UserContact.Status.Confirmed.rawValue
                    createChat(for: newContactRequest)
                    managedContext.saveContext()
                    
                    NotificationCenter.default.post(name: .newOnionMessageWasReceived,object:nil, userInfo: ["message": TransactionMessage()])
                }
            }
        }
        
    }
    
    //MARK: END Contact Add helpers
    
    
    //MARK: CoreData Helpers:
    
    func createSelfContact(scid:String,serverPubkey:String,myOkKey:String){
        
        self.pendingContact = UserContact(context: managedContext)
        self.pendingContact?.scid = scid
        self.pendingContact?.isOwner = true
        self.pendingContact?.index = 0
        self.pendingContact?.id = 0
        self.pendingContact?.publicKey = myOkKey
        self.pendingContact?.routeHint = "\(serverPubkey)_\(scid)"
        self.pendingContact?.status = UserContact.Status.Confirmed.rawValue
        self.pendingContact?.newMessages = 0
        self.pendingContact?.createdAt = Date()
        self.pendingContact?.fromGroup = false
        self.pendingContact?.privatePhoto = false
        self.pendingContact?.tipAmount = 0
        self.pendingContact?.blocked = false
        managedContext.saveContext()
    }
    
    func createNewContact(
        pubkey:String,
        nickname:String?=nil,
        photo_url:String?=nil,
        person:String? = nil,
        code:String?=nil
    ) -> UserContact?{
        
        let contact = UserContact.getContactWithInvitCode(inviteCode: code ?? "") ?? UserContact(context: managedContext)
        contact.id = Int(Int32(UUID().hashValue & 0x7FFFFFFF))
        contact.publicKey = pubkey//
        contact.isOwner = false//
        contact.nickname = nickname
        contact.createdAt = Date()
        contact.newMessages = 0
        contact.status = UserContact.Status.Pending.rawValue
        contact.createdAt = Date()
        contact.newMessages = 0
        contact.createdAt = Date()
        contact.fromGroup = false
        contact.privatePhoto = false
        contact.tipAmount = 0
        contact.blocked = false
        contact.avatarUrl = photo_url
        
        return contact
    }
    
    func createChat(for contact:UserContact){
        let contactID = NSNumber(value: contact.id)
        if let _ = Chat.getAll().filter({$0.contactIds.contains(contactID)}).first{
            return //don't make duplicates
        }
        let selfContactId =  0
        let chat = Chat(context: managedContext)
        let contactIDArray = [contactID,NSNumber(value: selfContactId)]
        chat.id = contact.id
        chat.type = Chat.ChatType.conversation.rawValue
        chat.status = Chat.ChatStatus.approved.rawValue
        chat.seen = false
        chat.muted = false
        chat.unlisted = false
        chat.privateTribe = false
        chat.notify = Chat.NotificationLevel.SeeAll.rawValue
        chat.contactIds = contactIDArray
        chat.name = contact.nickname
        chat.photoUrl = contact.avatarUrl
        chat.createdAt = Date()
    }
    //MARK: END CoreData Helpers
}


//MARK: Helper Structs & Functions:

// Parsing Helper Struct
struct SphinxOnionBrokerResponse: Mappable {
    var scid: String?
    var serverPubkey: String?
    var myPubkey: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        scid <- map["scid"]
        serverPubkey <- map["server_pubkey"]
    }
}

enum SphinxMsgError: Error {
    case encodingError
    case credentialsError //can't get access to my Private Keys/other data!
    case contactDataError // not enough data about contact!
}


