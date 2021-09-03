// PodcastFeed+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import CoreData

@objc(PodcastFeed)
public class PodcastFeed: NSManagedObject {
    
    var currentEpisode: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-\(chat?.id ?? -1)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-\(chat?.id ?? -1)")
        }
    }
    
    var currentEpisodeId: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-id-\(chat?.id ?? -1)") as? Int) ?? -1
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-id-\(chat?.id ?? -1)")
        }
    }
    
    var lastEpisodeId: Int? {
        get {
            return (UserDefaults.standard.value(forKey: "last-episode-id-\(chat?.id ?? -1)") as? Int)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last-episode-id-\(chat?.id ?? -1)")
        }
    }
    
    var currentTime: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-time-\(chat?.id ?? -1)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-time-\(chat?.id ?? -1)")
        }
    }
    
    var playerSpeed: Float {
        get {
            let speed = (UserDefaults.standard.value(forKey: "player-speed-\(chat?.id ?? -1)") as? Float) ?? 1.0
            return speed >= 0.5 && speed <= 2.1 ? speed : 1.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "player-speed-\(chat?.id ?? -1)")
        }
    }
    
    func getCurrentEpisode() -> PodcastEpisode? {
        let currentEpisodeIndex = getCurrentEpisodeIndex()
        let episodes = self.episodesArray
        
        guard episodes.isEmpty == false
        else { return nil }
        
        return episodes[currentEpisodeIndex]
    }
    
    func getCurrentEpisodeIndex() -> Int {
        let currentEId = currentEpisodeId
        return self.episodesArray.firstIndex(where: { $0.id == currentEId }) ?? currentEpisode
    }
    
}
