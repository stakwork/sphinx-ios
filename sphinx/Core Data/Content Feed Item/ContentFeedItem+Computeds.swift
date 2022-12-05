// ContentFeedItem+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation


extension ContentFeedItem {
    
    public var feedKind: FeedType {
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
    
