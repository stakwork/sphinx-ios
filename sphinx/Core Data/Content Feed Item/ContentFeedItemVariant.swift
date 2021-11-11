// ContentFeedItemVariant.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


protocol ContentFeedItemVariant: NSManagedObject, Decodable {
    var id: String { get }
    var contentKind: ContentFeedKind { get }
    var title: String { get }
    var itemDescription: String? { get }
    var datePublished: Date? { get }
    var enclosureURL: URL? { get }
    var enclosureKind: String? { get }
    var enclosureLength: Int64 { get }
    var imageURL: URL? { get }
    var linkURL: URL? { get }
}
