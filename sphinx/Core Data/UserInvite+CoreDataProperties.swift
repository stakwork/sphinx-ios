//
//  UserInvite+CoreDataProperties.swift
//  
//
//  Created by Tomas Timinskas on 06/11/2019.
//
//

import Foundation
import CoreData


extension UserInvite {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserInvite> {
        return NSFetchRequest<UserInvite>(entityName: "UserInvite")
    }

    @NSManaged public var inviteString: String?
    @NSManaged public var welcomeMessage: String?
    @NSManaged public var status: Int
    @NSManaged public var price: NSDecimalNumber?
    @NSManaged public var contact: UserContact?

}
