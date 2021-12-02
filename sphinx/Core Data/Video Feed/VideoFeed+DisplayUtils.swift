// VideoFeed+Computedsi.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension VideoFeed {
    
    var avatarImagePlaceholder: UIImage? {
        UIImage(named: "profile_avatar")
    }
    
    
    var titleForDisplay: String { title ?? "Untitled" }
    
    var authorNameForDisplay: String {
        if let author = author, !author.isEmpty {
            return author
        }
        return title ?? "Unknown author"
    }
}
