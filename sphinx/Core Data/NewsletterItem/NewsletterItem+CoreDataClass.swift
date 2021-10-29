//
//  NewsletterItem+CoreDataClass.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData

@objc(NewsletterItem)
public class NewsletterItem: NSManagedObject {
    
    static func getNewsletterItemWith(itemID: String) -> NewsletterItem? {
        let predicate = NSPredicate(format: "itemID == %@", itemID)
        let item:NewsletterItem? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "NewsletterItem")
        return item
    }
}


extension NewsletterItem: Identifiable {
    public var id: String { itemID }
}
