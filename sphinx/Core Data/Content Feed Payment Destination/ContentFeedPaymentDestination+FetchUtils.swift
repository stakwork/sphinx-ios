//
//  ContentFeedPaymentDestination+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/04/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension ContentFeedPaymentDestination {
    
    public static func deleteDestinationForFeedWith(id: String) {
        if let feed = ContentFeed.getFeedById(feedId: id) {
            for destination in  feed.destinationsArray {
                CoreDataManager.sharedManager.deleteObject(object: destination)
            }
        }
    }
}
