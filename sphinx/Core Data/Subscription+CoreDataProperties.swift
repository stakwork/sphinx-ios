//
//  Subscription+CoreDataProperties.swift
//  
//
//  Created by Tomas Timinskas on 20/11/2019.
//
//

import Foundation
import CoreData


extension Subscription {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subscription> {
        return NSFetchRequest<Subscription>(entityName: "Subscription")
    }

    @NSManaged public var id: Int
    @NSManaged public var cron: String?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var endNumber: Int
    @NSManaged public var count: Int
    @NSManaged public var endDate: Date?
    @NSManaged public var ended: Bool
    @NSManaged public var paused: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var chat: Chat?
    @NSManaged public var contact: UserContact?

}
