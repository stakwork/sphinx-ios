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
        if
            let managedObjectContext = decoder
                .userInfo[.managedObjectContext]
                as? NSManagedObjectContext
        {
            self.init(context: managedObjectContext)
        } else {
            self.init(entity: ContentFeedPaymentModel.entity(), insertInto: nil)
        }
        
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        suggestedBTC = Double(
            try container.decode(String.self, forKey: .suggestedBTC)
        ) ?? 0
        
        type = try container.decode(String.self, forKey: .type)
    }
}
