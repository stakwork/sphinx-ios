// ContentFeedItem+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation


extension ContentFeedItem {
    
    public var contentKind: ContentFeedKind {
        get {
            .init(rawValue: contentKindValue)!
        }
        set {
            contentKindValue = newValue.rawValue
        }
    }
}
    
