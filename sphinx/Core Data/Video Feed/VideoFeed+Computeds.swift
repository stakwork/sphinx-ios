// VideoFeed+Computedsi.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation

extension VideoFeed {
    
    var videosArray: [Video] {
        guard let videos = videos else {
            return []
        }
        
        return videos.sorted { (first, second) in
            if first.datePublished == nil {
                return false
            } else if second.datePublished == nil {
                return true
            }
            
            return first.datePublished! > second.datePublished!
        }
    }
    
}
