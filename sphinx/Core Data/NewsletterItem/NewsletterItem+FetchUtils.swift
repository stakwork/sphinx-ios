//
//  NewsletterItem+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/11/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Predicates
extension NewsletterItem {
    static func getNewsletterItemWith(itemID: String) -> NewsletterItem? {
        let predicate = NSPredicate(format: "itemID == %@", itemID)
        let item:NewsletterItem? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "NewsletterItem")
        return item
    }
}
