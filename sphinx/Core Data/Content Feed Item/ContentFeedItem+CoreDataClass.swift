// ContentFeedItemVariant.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


@objc(ContentFeedItem)
public final class ContentFeedItem: NSManagedObject, ContentFeedItemVariant {

    // MARK: - Decodable
    public required convenience init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.managedObjectContext]
                as? NSManagedObjectContext
        else {
            preconditionFailure("No managedObjectContext found in decoder userInfo")
        }
        
        self.init(context: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)

        itemID = try container.decode(String.self, forKey: .itemID)
        title = try container.decode(String.self, forKey: .title)
        authorName = try container.decode(String.self, forKey: .authorName)
        itemDescription = try container.decode(String.self, forKey: .itemDescription)
        feedKindValue = try container.decode(Int16.self, forKey: .feedKindValue)
        mediaKindValue = try container.decode(String.self, forKey: .mediaKindValue)
        datePublished = try container.decode(Date.self, forKey: .datePublished)
        enclosureURL = try? container.decode(URL.self, forKey: .enclosureURL)
        enclosureKind = try container.decode(String.self, forKey: .enclosureKind)
        enclosureLength = try container.decode(Int64.self, forKey: .enclosureLength)
        imageURL = try? container.decode(URL.self, forKey: .imageURL)
        linkURL = try? container.decode(URL.self, forKey: .linkURL)
    }
}

