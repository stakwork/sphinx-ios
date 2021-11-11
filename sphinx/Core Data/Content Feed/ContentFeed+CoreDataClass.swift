// ContentFeed+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


@objc(ContentFeed)
public class ContentFeed: NSManagedObject, Decodable {
    
    // MARK: - Decodable
    public required convenience init(from decoder: Decoder) throws {
        guard
            let managedObjectContext = decoder
                .userInfo[.managedObjectContext]
                as? NSManagedObjectContext
        else {
            preconditionFailure("No managedObjectContext found in decoder userInfo")
        }
        
        self.init(context: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        feedID = try container.decode(String.self, forKey: .feedID)
        title = try container.decode(String.self, forKey: .title)
        feedKindValue = try container.decode(ContentFeedKind.RawValue.self, forKey: .feedKindValue)
        ownerURL = try container.decode(URL.self, forKey: .ownerURL)
        generator = try container.decode(String.self, forKey: .generator)
        authorName = try container.decode(String.self, forKey: .authorName)
        imageURL = try container.decode(URL.self, forKey: .imageURL)
        feedDescription = try container.decode(String.self, forKey: .feedDescription)
        feedURL = try container.decode(URL.self, forKey: .feedURL)
        linkURL = try container.decode(URL.self, forKey: .linkURL)
        datePublished = try container.decode(Date.self, forKey: .datePublished)
        dateUpdated = try container.decode(Date.self, forKey: .dateUpdated)
        language = try container.decode(String.self, forKey: .language)
        
        items = try .init(from: decoder)
    }
}
