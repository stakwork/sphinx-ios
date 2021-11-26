// ContentFeedPaymentDestination+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


@objc(ContentFeedPaymentDestination)
public class ContentFeedPaymentDestination: NSManagedObject, Decodable {
    
    // MARK: - Decodable
    public required convenience init(from decoder: Decoder) throws {
        if
            let managedObjectContext = decoder
                .userInfo[.managedObjectContext]
                as? NSManagedObjectContext
        {
            self.init(context: managedObjectContext)
        } else {
            self.init(entity: ContentFeedPaymentDestination.entity(), insertInto: nil)
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        address = try container.decodeIfPresent(String.self, forKey: .address)
        split = try container.decode(Double.self, forKey: .split)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        customKey = try container.decodeIfPresent(String.self, forKey: .customKey)
        customValue = try container.decodeIfPresent(String.self, forKey: .customValue)
    }
}
