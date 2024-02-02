//
//  Chat+CoreDataProperties.swift
//  
//
//  Created by Tomas Timinskas on 06/11/2019.
//
//

import Foundation
import CoreData

extension Chat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chat> {
        return NSFetchRequest<Chat>(entityName: "Chat")
    }

    @NSManaged public var id: Int
    @NSManaged public var uuid: String?
    @NSManaged public var name: String?
    @NSManaged public var photoUrl: String?
    @NSManaged public var type: Int
    @NSManaged public var status: Int
    @NSManaged public var createdAt: Date
    @NSManaged public var muted: Bool
    @NSManaged public var seen: Bool
    @NSManaged public var host: String?
    @NSManaged public var groupKey: String?
    @NSManaged public var ownerPubkey: String?
    @NSManaged public var priceToJoin: NSDecimalNumber?
    @NSManaged public var pricePerMessage: NSDecimalNumber?
    @NSManaged public var escrowAmount: NSDecimalNumber?
    @NSManaged public var unlisted: Bool
    @NSManaged public var privateTribe: Bool
    @NSManaged public var myAlias: String?
    @NSManaged public var myPhotoUrl: String?
    @NSManaged public var webAppLastDate: Date?
    @NSManaged public var pin: String?
    @NSManaged public var pinnedMessageUUID: String?
    @NSManaged public var notify: Int
    @NSManaged public var pinnedMessageUUI: String?
    @NSManaged public var contentFeed: ContentFeed?
    @NSManaged public var contactIds: [NSNumber]
    @NSManaged public var pendingContactIds: [NSNumber]

    @NSManaged public var isTribeICreated: Bool
    @NSManaged public var messages: NSSet?
    @NSManaged public var cachedMediaSet: NSSet?
    @NSManaged public var subscription: Subscription?
    @NSManaged public var lastMessage: TransactionMessage?
}


// MARK: Generated accessors for messages
extension Chat {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: TransactionMessage)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: TransactionMessage)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
    
    @objc(addCachedMediaSetObject:)
    @NSManaged public func addToCachedMediaSet(_ value: CachedMedia)

    @objc(removeCachedMediaSetObject:)
    @NSManaged public func removeFromCachedMediaSet(_ value: CachedMedia)

    @objc(addCachedMediaSet:)
    @NSManaged public func addToCachedMediaSet(_ values: NSSet)

    @objc(removeCachedMediaSet:)
    @NSManaged public func removeFromCachedMediaSet(_ values: NSSet)

}

extension Chat : Identifiable {}
