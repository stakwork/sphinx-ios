//
//  NewsletterFeed+CoreDataClass.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData

@objc(NewsletterFeed)
public class NewsletterFeed: NSManagedObject {

}

extension NewsletterFeed: Identifiable {
    public var id: String { feedID }
}
