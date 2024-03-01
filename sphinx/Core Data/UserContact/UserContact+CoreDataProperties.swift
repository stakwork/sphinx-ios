//
//  UserContact+CoreDataProperties.swift
//  
//
//  Created by Tomas Timinskas on 06/11/2019.
//
//

import Foundation
import CoreData


extension UserContact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserContact> {
        return NSFetchRequest<UserContact>(entityName: "UserContact")
    }

    @NSManaged public var id: Int
    @NSManaged public var publicKey: String?
    @NSManaged public var nickname: String?
    @NSManaged public var nodeAlias: String?
    @NSManaged public var avatarUrl: String?
    @NSManaged public var status: Int
    @NSManaged public var createdAt: Date
    @NSManaged public var email: String?
    @NSManaged public var isOwner: Bool
    @NSManaged public var newMessages: Int
    @NSManaged public var phoneNumber: String?
    @NSManaged public var timeZone: String?
    @NSManaged public var contactKey: String?
    @NSManaged public var fromGroup: Bool
    @NSManaged public var invite: UserInvite?
    @NSManaged public var subscriptions: NSSet?
    @NSManaged public var privatePhoto: Bool
    @NSManaged public var notificationSound: String?
    @NSManaged public var tipAmount: Int
    @NSManaged public var pin: String?
    @NSManaged public var routeHint: String?
    @NSManaged public var blocked: Bool
    @NSManaged public var scid: String?
    @NSManaged public var index: Int
    @NSManaged public var sentInviteCode : String?

}

// MARK: Generated accessors for chats
extension UserContact {
    
    @objc(addSubscriptionsObject:)
    @NSManaged public func addToSubscriptions(_ value: Subscription)

    @objc(removeSubscriptionsObject:)
    @NSManaged public func removeFromSubscription(_ value: Subscription)

    @objc(addSubscriptions:)
    @NSManaged public func addToSubscription(_ values: NSSet)

    @objc(removeSubscriptions:)
    @NSManaged public func removeFromSubscription(_ values: NSSet)

}
