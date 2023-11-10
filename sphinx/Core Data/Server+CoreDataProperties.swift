//
//  Server+CoreDataProperties.swift
//  sphinx
//
//  Created by James Carucci on 11/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CoreData

extension Server {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Server> {
        return NSFetchRequest<Server>(entityName: "Server")
    }

    @NSManaged public var ip: String?
    @NSManaged public var pubKey: String?

}
