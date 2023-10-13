//
//  TransactionMessage+CoreDataProperties.swift
//  
//
//  Created by Tomas Timinskas on 06/11/2019.
//
//

import Foundation
import CoreData


extension TransactionMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionMessage> {
        return NSFetchRequest<TransactionMessage>(entityName: "TransactionMessage")
    }

    @NSManaged public var id: Int
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var receiverId: Int
    @NSManaged public var senderId: Int
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var amountMsat: NSDecimalNumber?
    @NSManaged public var type: Int
    @NSManaged public var status: Int
    @NSManaged public var date: Date?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var paymentHash: String?
    @NSManaged public var invoice: String?
    @NSManaged public var messageContent: String?
    @NSManaged public var seen: Bool
    @NSManaged public var encrypted: Bool
    @NSManaged public var senderAlias: String?
    @NSManaged public var senderPic: String?
    @NSManaged public var recipientAlias: String?
    @NSManaged public var recipientPic: String?
    @NSManaged public var uuid: String?
    @NSManaged public var replyUUID: String?
    @NSManaged public var originalMuid: String?
    @NSManaged public var chat: Chat?
    @NSManaged public var push: Bool
    @NSManaged public var person: String?
    @NSManaged public var errorMessage: String?
    
    @NSManaged public var mediaKey: String?
    @NSManaged public var mediaType: String?
    @NSManaged public var mediaToken: String?
    @NSManaged public var mediaFileName: String?
    @NSManaged public var mediaFileSize: Int
    @NSManaged public var muid: String?
    @NSManaged public var threadUUID: String?
}
