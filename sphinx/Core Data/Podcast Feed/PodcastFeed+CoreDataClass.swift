// PodcastFeed+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData

@objc(PodcastFeed)
public class PodcastFeed: NSManagedObject {
    
    var identifier: Int {
        get {
            chat?.id ?? Int(feedID) ?? -1
        }
    }
    
    var currentEpisode: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-\(identifier)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-\(identifier)")
        }
    }
    
    var currentEpisodeId: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-id-\(identifier)") as? Int) ?? -1
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-id-\(identifier)")
        }
    }
    
    var lastEpisodeId: Int? {
        get {
            return (UserDefaults.standard.value(forKey: "last-episode-id-\(identifier)") as? Int)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last-episode-id-\(identifier)")
        }
    }
    
    var currentTime: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-time-\(identifier)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-time-\(identifier)")
        }
    }
    
    var playerSpeed: Float {
        get {
            let speed = (UserDefaults.standard.value(forKey: "player-speed-\(identifier)") as? Float) ?? 1.0
            return speed >= 0.5 && speed <= 2.1 ? speed : 1.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "player-speed-\(identifier)")
        }
    }
    
    func getCurrentEpisode() -> PodcastEpisode? {
        let currentEpisodeIndex = getCurrentEpisodeIndex()
        let episodes = self.episodesArray
        
        guard !episodes.isEmpty && currentEpisodeIndex < episodes.count
        else { return nil }
        
        return episodes[currentEpisodeIndex]
    }
    
    func getCurrentEpisodeIndex() -> Int {
        let currentEId = currentEpisodeId
        
        return episodesArray
            .firstIndex(where: { Int($0.itemID) ?? -1 == currentEId })
            ?? currentEpisode
    }
    
}
