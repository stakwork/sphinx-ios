//
//  CachedMedia+CoreDataClass.swift
//  sphinx
//
//  Created by James Carucci on 5/11/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc(CachedMedia)
public class CachedMedia: NSManagedObject {
    
    
    public static func getCachedMediaInstance(id: Int, managedContext: NSManagedObjectContext) -> CachedMedia {
        if let cm = CachedMedia.getCachedMediaWith(id: id) {
            return cm
        } else {
            return CachedMedia(context: managedContext) as CachedMedia
        }
    }
    
    public static func getCachedMediaWith(id: Int) -> CachedMedia? {
        let predicate = NSPredicate(format: "id == %d", id)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let cachedMedia:CachedMedia? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "CachedMedia")
        return cachedMedia
    }
    
    public static func createObject(id: Int, chat: Chat?,filePath:String?,fileExtension:String?,key:String? ) -> CachedMedia? {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let cachedMedia = getCachedMediaInstance(id: id, managedContext: managedContext)

        cachedMedia.id = id
        cachedMedia.chat = chat
        cachedMedia.filePath = filePath
        cachedMedia.fileExtension = fileExtension
        cachedMedia.key = key
        
        managedContext.saveContext()
        
        return cachedMedia
    }
    
    public static func getAll() -> [CachedMedia] {
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let cachedMedia: [CachedMedia] = CoreDataManager.sharedManager.getAllOfType(entityName: "CachedMedia", sortDescriptors: sortDescriptors)
        return cachedMedia
    }
    
    
}
