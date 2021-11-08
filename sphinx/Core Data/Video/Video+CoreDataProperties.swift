// Video+CoreDataProperties.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData


extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var videoID: String
    @NSManaged public var datePublished: Date?
    @NSManaged public var dateUpdated: Date?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var videoDescription: String?
    @NSManaged public var videoShortDescription: String?
    @NSManaged public var itemURL: URL?
    @NSManaged public var mediaURL: URL?
    @NSManaged public var thumbnailURL: URL?
    @NSManaged public var videoFeed: VideoFeed?
}
