//
//  NewsletterFeed+Computeds.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation

extension NewsletterFeed {
    
    var identifier: String {
        get {
            if let chatId = chat?.id {
                return String(chatId)
            }
            return feedID
        }
    }
    
    var currentArticleID: String? {
        get {
            return (UserDefaults.standard.value(forKey: "current-article-id-\(identifier)") as? String) ?? nil
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-article-id-\(identifier)")
        }
    }
    
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
    
    var nextArticle: NewsletterItem {
        let nextArticle = currentArticleIndex - 1
        
        if itemsArray.count > nextArticle && nextArticle >= 0 {
            return itemsArray[nextArticle]
        }
        return itemsArray.first!
    }
    
    var currentArticleIndex: Int {
        if let currentAId = currentArticleID {
            return itemsArray.firstIndex(where: { $0.id == currentAId }) ?? 0
        }
        return 0
    }
    
    var avatarImageURL: URL? {
        guard let urlPath = chat?.photoUrl else {
            return nil
        }
        
        return URL(string: urlPath)
    }
}
