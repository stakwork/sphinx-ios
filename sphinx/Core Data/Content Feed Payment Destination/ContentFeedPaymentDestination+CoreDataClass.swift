// ContentFeedPaymentDestination+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData
import SwiftyJSON

@objc(ContentFeedPaymentDestination)
public class ContentFeedPaymentDestination: NSManagedObject {
    
    public static func createObjectFrom(
        json: JSON,
        context: NSManagedObjectContext? = nil
    ) -> ContentFeedPaymentDestination? {
        
        var paymentDestination: ContentFeedPaymentDestination
        
        if let managedObjectContext = context {
            paymentDestination = ContentFeedPaymentDestination(context: managedObjectContext)
        } else {
            paymentDestination = ContentFeedPaymentDestination(entity: ContentFeedPaymentDestination.entity(), insertInto: nil)
        }
        
        paymentDestination.address = json[CodingKeys.address.rawValue].stringValue
        paymentDestination.split = json[CodingKeys.split.rawValue].doubleValue
        paymentDestination.type = json[CodingKeys.type.rawValue].stringValue
        paymentDestination.customKey = json[CodingKeys.customKey.rawValue].stringValue
        paymentDestination.customValue = json[CodingKeys.customValue.rawValue].stringValue
        
        return paymentDestination
    }
}
