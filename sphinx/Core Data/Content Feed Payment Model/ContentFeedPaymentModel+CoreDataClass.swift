// ContentFeedPaymentModel+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData
import SwiftyJSON


@objc(ContentFeedPaymentModel)
public class ContentFeedPaymentModel: NSManagedObject {
    
    public static func createObjectFrom(
        json: JSON,
        context: NSManagedObjectContext? = nil
    ) -> ContentFeedPaymentModel? {
        
        var paymentModel: ContentFeedPaymentModel
        
        if let managedObjectContext = context {
            paymentModel = ContentFeedPaymentModel(context: managedObjectContext)
        } else {
            paymentModel = ContentFeedPaymentModel(entity: ContentFeedPaymentModel.entity(), insertInto: nil)
        }
        
        paymentModel.suggestedBTC = Double(json[CodingKeys.suggestedBTC.rawValue].stringValue) ?? 0.0
        paymentModel.type = json[CodingKeys.type.rawValue].stringValue
        
        return paymentModel
    }
    
    var suggestedSats: Int { Int(round(suggestedBTC * Double(Constants.satoshisInBTC))) }
}
