//
//  Action+CoreDataClass.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc(ActionTrack)
public class ActionTrack: NSManagedObject, Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.type, forKey: .type)
        try container.encode(self.metaData, forKey: .metaData)
    }
    
    static func createObject(
        type: Int,
        uploaded: Bool,
        metaData: String
    ) -> ActionTrack? {
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let action = ActionTrack(context: managedContext) as ActionTrack
        
        action.type = type
        action.uploaded = uploaded
        action.metaData = metaData
        
        CoreDataManager.sharedManager.saveContext()
        
        return action
    }
    
    static func getAll() -> [ActionTrack] {
        let actions : [ActionTrack] = CoreDataManager.sharedManager.getAllOfType(entityName: "ActionTrack", sortDescriptors: [])
        return actions
    }
    
    func jsonString() -> String? {
        let jsonEncoder = JSONEncoder()
        var jsonData: Data! = nil
        do {
            jsonData = try jsonEncoder.encode(self)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return String(data: jsonData, encoding: String.Encoding.utf8)
    }
}

extension ActionTrack {
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case metaData = "meta_data"
    }
}
    
