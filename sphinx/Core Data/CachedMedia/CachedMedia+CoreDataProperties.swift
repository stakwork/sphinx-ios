//
//  CachedMedia+CoreDataProperties.swift
//  sphinx
//
//  Created by James Carucci on 5/11/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CoreData


extension CachedMedia {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedMedia> {
        return NSFetchRequest<CachedMedia>(entityName: "CachedMedia")
    }

    @NSManaged public var id: Int
    @NSManaged public var chat: Chat?
    @NSManaged public var fileExtension: String?
    @NSManaged public var filePath: String?
    @NSManaged public var key: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var fileName: String?
}
