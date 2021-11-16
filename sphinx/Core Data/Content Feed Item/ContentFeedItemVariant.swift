// ContentFeedItemVariant.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


protocol ContentFeedItemVariant: NSManagedObject, Decodable {
    var itemID: String { get }
    var feedKind: ContentFeedKind { get }
    var contentMediaKind: ContentFeedMediaKind { get }
    var title: String { get }
    var itemDescription: String? { get }
    var datePublished: Date? { get }
    var enclosureURL: URL? { get }
    var enclosureKind: String? { get }
    var enclosureLength: Int64 { get }
    var imageURL: URL? { get }
    var linkURL: URL? { get }
}
