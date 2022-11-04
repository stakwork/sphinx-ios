//
//  Action+CoreDataProperties.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData

extension ActionTrack {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActionTrack> {
        return NSFetchRequest<ActionTrack>(entityName: "ActionTrack")
    }

    @NSManaged public var type: Int
    @NSManaged public var metaData: String
    @NSManaged public var uploaded: Bool

}


extension ActionTrack : Identifiable {}
