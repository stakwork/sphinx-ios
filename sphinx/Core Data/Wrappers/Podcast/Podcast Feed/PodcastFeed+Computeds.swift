import Foundation
import CoreData


extension PodcastFeed {
    
    var episodesArray: [PodcastEpisode] {
        guard let episodes = episodes else {
            return []
        }
        
        return episodes.sorted { (first, second) in
            if first.datePublished == nil {
                return false
            } else if second.datePublished == nil {
                return true
            }
            
            return first.datePublished! > second.datePublished!
        }
    }
    
    
    var destinationsArray: [PodcastDestination] {
        guard let destinations = destinations else { return [] }
        
        return Array(destinations)
    }
}

extension PodcastFeed {
    
    var identifier: Int {
        get {
            chat?.id ?? Int(feedID) ?? -1
        }
    }
    
    var currentEpisodeIndex: Int {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-\(identifier)") as? Int) ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-\(identifier)")
        }
    }
    
    var currentEpisodeId: String {
        get {
            return (UserDefaults.standard.value(forKey: "current-episode-item-id-\(identifier)") as? String) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "current-episode-item-id-\(identifier)")
        }
    }
    
    var lastEpisodeId: String? {
        get {
            return (UserDefaults.standard.value(forKey: "last-episode-item-id-\(identifier)") as? String)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last-episode-item-id-\(identifier)")
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
    
    var isRecommendationsPodcast: Bool {
        feedID == RecommendationsHelper.kRecommendationPodcastId
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
            .firstIndex(where: { $0.itemID == currentEId })
            ?? currentEpisodeIndex
    }
    
    func getEpisodeInfo() -> (String, String) {
        let episode = getCurrentEpisode()
        
        return (episode?.title ?? "Episode with no title", episode?.imageURLPath ?? "")
    }
    
    func getEpisodeWith(id: String) -> PodcastEpisode? {
        return episodesArray.first(where: { $0.itemID == id })
    }
    
    func getItemRankForEpisodeWithId(id: String) -> Int {
        for (i, item) in (episodes ?? []).enumerated() {
            if (item.itemID == id) {
                return i + 1
            }
        }
        return 0
    }
    
    func getImageURL() -> URL? {
        let (_, episodeImage) = getEpisodeInfo()
        if let imageURL = URL(string: episodeImage), !episodeImage.isEmpty {
            return imageURL
        }
        let urlPath = imageURLPath ?? ""
        if let imageURL = URL(string: urlPath), !urlPath.isEmpty {
            return imageURL
        }
        return nil
    }
    
    func getPodcastComment() -> PodcastComment {
        let episode = getCurrentEpisode()
        
        var comment = PodcastComment()
        comment.feedId = feedID
        comment.feedItemObjectId = episode?.objectID
        comment.itemId = episode?.itemID
        comment.title = episode?.title
        comment.url = episode?.urlPath
        comment.timestamp = currentTime
        
        return comment
    }
    
}
