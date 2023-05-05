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
        
        if !sortedVideosArray.isEmpty {
            return sortedVideosArray
        }
        
        sortedVideosArray = videos.sorted { (first, second) in
            if first.datePublished == nil {
                return false
            } else if second.datePublished == nil {
                return true
            }
            
            return first.datePublished! > second.datePublished!
        }
        
        return sortedVideosArray
    }
    
    
    var avatarImageURL: URL? {
        guard let urlPath = chat?.photoUrl else {
            return nil
        }
        
        return URL(string: urlPath)
    }
    
    
    var isYouTubeFeed: Bool {
        guard let feedURL = feedURL else { return false }
        
        return feedURL.absoluteString.isYouTubeRSSFeed
    }
}
