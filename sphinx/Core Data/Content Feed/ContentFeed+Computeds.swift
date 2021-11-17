// ContentFeed+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


extension ContentFeed {
    
    public var feedKind: ContentFeedKind {
        get {
            .init(rawValue: feedKindValue)!
        }
        set {
            feedKindValue = newValue.rawValue
        }
    }
    
    
    public var contentMediaKind: ContentFeedMediaKind {
        get {
            .init(rawValue: mediaKindValue)!
        }
        set {
            mediaKindValue = newValue.rawValue
        }
    }
}
