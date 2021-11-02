// Video+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//
    
//

import Foundation
import CoreData

@objc(Video)
public class Video: NSManagedObject {

    static func getVideoWith(videoID: String) -> Video? {
        let predicate = NSPredicate(format: "videoID == %@", videoID)
        let video:Video? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "Video")
        return video
    }
    
}


extension Video: Identifiable {
    public var id: String { videoID }
}

