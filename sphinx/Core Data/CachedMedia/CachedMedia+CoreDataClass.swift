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
import UIKit
import SDWebImage

@objc(CachedMedia)
public class CachedMedia: NSManagedObject {
    public var image : UIImage?
    public var isVideo : Bool?
    
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
    
    public static func getTruncatedFilePath(filePath:String?)->String?{
        let delimiter = "/Caches/"
        if let path = filePath,
           path.components(separatedBy: delimiter).count > 1{
            return String(path.components(separatedBy: delimiter)[1])
        }
        return nil
    }
    
    public static func createObject(
        id: Int,
        chat: Chat?,
        filePath: String?,
        fileExtension: String?,
        key: String?,
        fileName: String?
    ) -> CachedMedia? {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let cachedMedia = getCachedMediaInstance(id: id, managedContext: managedContext)

        cachedMedia.id = id
        
        if let chat = chat {
            cachedMedia.chat = chat
        }
        
        if let truncatedPath = CachedMedia.getTruncatedFilePath(filePath: filePath){
            cachedMedia.filePath = truncatedPath
        }
        
        cachedMedia.fileExtension = fileExtension
        cachedMedia.key = key
        cachedMedia.fileName = fileName
        cachedMedia.creationDate = Date()
        
        managedContext.saveContext()
        
        return cachedMedia
    }
    
    func removeSphinxCacheObject(completion:@escaping ()->()){
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        if let key = key{
            let _ = SphinxCache().removeFromDisk(forKey: key)
            managedContext.delete(self)
            managedContext.saveContext()
            completion()
        }
        
    }
    
    func removePhotoObject(completion: @escaping ()->()) {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        if let key = self.key{
            MediaLoader.clearImageCacheFor(url: key)
            managedContext.delete(self)
            managedContext.saveContext()
            completion()
        }
    }
    
    public static func getAll() -> [CachedMedia] {
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let cachedMedia: [CachedMedia] = CoreDataManager.sharedManager.getAllOfType(entityName: "CachedMedia", sortDescriptors: sortDescriptors)
        return cachedMedia
    }
    
    public static func getCachedMediaByKey(key: String, managedContext: NSManagedObjectContext? = nil) -> CachedMedia? {
        let predicate = MediaPredicates.matching(key: key)
        let cm: CachedMedia? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "CachedMedia", managedContext: managedContext)
        return cm
    }
    
    public static func getCachedMediaByFilePath(filePath: String, managedContext: NSManagedObjectContext? = nil,isVideo:Bool) -> CachedMedia? {
        
        guard let truncatedPath = CachedMedia.getTruncatedFilePath(filePath: filePath) else{
            return nil
        }
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
            
        let fetchRequest: NSFetchRequest<CachedMedia> = CachedMedia.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "filePath == %@", truncatedPath)
        fetchRequest.fetchLimit = 1
        fetchRequest.relationshipKeyPathsForPrefetching = ["chat"]
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            let result = results.first
            result?.isVideo = isVideo
            return results.first
        } catch {
            print("Error fetching cached media: \(error)")
            return nil
        }
    }
    
    
}


public enum MediaPredicates {
    
    public static func matching(key: String) -> NSPredicate {
        let keyword = "=="
        let formatSpecifier = "%@"

        return NSPredicate(
            format: "%K \(keyword) \(formatSpecifier)",
            "key",
            key
        )
    }
    
    public static func matching(filePath: String) -> NSPredicate {
        let keyword = "=="
        let formatSpecifier = "%@"

        return NSPredicate(
            format: "%K \(keyword) \(formatSpecifier)",
            "filePath",
            filePath
        )
    }
    
}
