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
    
    func parseContactInfoString(routeHint:String)->(String,String,String)?{
        let components = routeHint.split(separator: "_").map({String($0)})
        if components.count != 3 {return nil}
        return (components.count == 3) ? (components[0],components[1],components[2]) : nil
    }
    
    func makeFriendRequest(
        contactInfo:String,
        nickname:String?=nil
    ){
        guard let (recipientPubkey, recipLspPubkey,scid) = parseContactInfoString(routeHint: contactInfo) else{
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
            let rr = try addContact(seed: seed, uniqueTime: getEntropyString(), state: loadOnionStateAsData(), toPubkey: recipientPubkey, routeHint: "\(recipLspPubkey)_\(scid)", myAlias: selfContact.nickname ?? "", myImg: "", amtMsat: 0)
            handleRunReturn(rr: rr)
        }
        catch{
            
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
        self.pendingContact?.childPubKey = "" // not possible for self
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
        person:String? = nil
    ) -> UserContact?{
        let contact = UserContact(context: managedContext)
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


