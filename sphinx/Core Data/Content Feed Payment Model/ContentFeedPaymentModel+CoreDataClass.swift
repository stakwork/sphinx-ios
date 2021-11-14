// ContentFeedPaymentModel+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData


@objc(ContentFeedPaymentModel)
public class ContentFeedPaymentModel: NSManagedObject, Decodable {

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
        
        suggestedBTC = Double(
            try container.decode(String.self, forKey: .suggestedBTC)
        ) ?? 0
        
        type = try container.decode(String.self, forKey: .type)
    }
}
