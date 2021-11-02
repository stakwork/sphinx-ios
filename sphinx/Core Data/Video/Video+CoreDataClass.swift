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

}


extension Video: Identifiable {
    public var id: String { videoID }
}

