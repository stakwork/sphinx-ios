//
//  NewsletterFeed+Computeds.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation

extension NewsletterFeed {
    
    var itemsArray: [NewsletterItem] {
        guard let newsletterItems = newsletterItems else {
            return []
        }
        
        return newsletterItems.sorted { (first, second) in
            if first.datePublished == nil {
                return false
            } else if second.datePublished == nil {
                return true
            }
            
            return first.datePublished! > second.datePublished!
        }
    }
    
    
    var avatarImageURL: URL? {
        guard let urlPath = chat?.photoUrl else {
            return nil
        }
        
        return URL(string: urlPath)
    }
}
