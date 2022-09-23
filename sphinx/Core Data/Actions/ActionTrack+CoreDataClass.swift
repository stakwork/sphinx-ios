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
public class ActionTrack: NSManagedObject {
    
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
}
    
