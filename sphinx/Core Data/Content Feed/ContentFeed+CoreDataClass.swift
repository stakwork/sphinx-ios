// ContentFeed+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData

@objc(ContentFeed)
public class ContentFeed: NSManagedObject, Decodable {
    
    enum Decoders {
        static let `default`: JSONDecoder = {
            let decoder = JSONDecoder()
            
            decoder.dateDecodingStrategy = .secondsSince1970
            
            return decoder
        }()
    }
    
    
    // MARK: - Decodable
    public required convenience init(from decoder: Decoder) throws {
        if
            let managedObjectContext = decoder
                .userInfo[.managedObjectContext]
                as? NSManagedObjectContext
        {
            self.init(context: managedObjectContext)
        } else {
            self.init(entity: ContentFeed.entity(), insertInto: nil)
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        feedID = try container.decode(String.self, forKey: .feedID)
        title = try? container.decode(String.self, forKey: .title)
        feedKindValue = try container.decode(FeedType.RawValue.self, forKey: .feedKindValue)
        ownerURL = try? container.decode(URL.self, forKey: .ownerURL)
        generator = try? container.decode(String.self, forKey: .generator)
        authorName = try? container.decode(String.self, forKey: .authorName)
        imageURL = try? container.decode(URL.self, forKey: .imageURL)
        feedDescription = try? container.decode(String.self, forKey: .feedDescription)
        feedURL = try? container.decode(URL.self, forKey: .feedURL)
        linkURL = try? container.decode(URL.self, forKey: .linkURL)
        datePublished = try? container.decode(Date.self, forKey: .datePublished)
        dateUpdated = try? container.decode(Date.self, forKey: .dateUpdated)
        language = try? container.decode(String.self, forKey: .language)
        
        if let newItems = try? container.decode(Set<ContentFeedItem>.self, forKey: .items) {
            items = newItems
        }

        if
            let valueContainer = try? container.nestedContainer(keyedBy: CodingKeys.Value.self, forKey: .value)
        {
            if let model = try? valueContainer.decode(ContentFeedPaymentModel.self, forKey: .paymentModel) {
                paymentModel = model
            }

            if let newPaymentDestinations = try? valueContainer.decode(
                Set<ContentFeedPaymentDestination>.self,
                forKey: .paymentDestinations
            ) {
                paymentDestinations = newPaymentDestinations
            }
        }
    }
}
