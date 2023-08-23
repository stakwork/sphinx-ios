import Foundation
import CoreData


extension PodcastFeed {
    
    var episodesArray: [PodcastEpisode] {
        guard let episodes = episodes else {
            return []
        }
        
        if !sortedEpisodesArray.isEmpty {
            return sortedEpisodesArray
        }
        
        sortedEpisodesArray = episodes.sorted { (first, second) in
            if first.datePublished == nil {
                return false
            } else if second.datePublished == nil {
                return true
            }
            
            return first.datePublished! > second.datePublished!
        }
        
        return sortedEpisodesArray
    }
    
    
    var destinationsArray: [PodcastDestination] {
        guard let destinations = destinations else { return [] }
        
        return Array(destinations)
    }
}

extension PodcastFeed {
    
    public static let kClipPrefix = "clip::"
    public static let kBoostPrefix = "boost::"
    
    var identifier: Int {
        get {
            chat?.id ?? Int(feedID) ?? -1
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
            return getCurrentEpisode()?.currentTime ?? 0
        }
        set {
            getCurrentEpisode()?.currentTime = newValue
        }
    }
    
    var duration: Int {
        get {
            return getCurrentEpisode()?.duration ?? 0
        }
        set {
            getCurrentEpisode()?.duration = newValue
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
    
    var satsPerMinute: Int? {
        get {
            return (UserDefaults.standard.value(forKey: "podcast-sats-\(identifier)") as? Int)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "podcast-sats-\(identifier)")
        }
    }
    
    func getCurrentEpisode() -> PodcastEpisode? {
        if let currentEpisode = episodesArray.first(where: { $0.itemID == currentEpisodeId }) {
            return currentEpisode
        }
        return episodesArray.first
    }
    
    func getNextEpisode() -> PodcastEpisode? {
        if let currentEpisodeIndex = currentEpisodeIndex, currentEpisodeIndex > 0 {
            if episodesArray.count > currentEpisodeIndex - 1 {
                return episodesArray[currentEpisodeIndex - 1]
            }
        }
        return nil
    }
    
    func getLastEpisode() -> PodcastEpisode? {
        return episodesArray.first
    }
    
    func getEpisodesToCache() -> [PodcastEpisode] {
        if let currentEpisodeIndex = currentEpisodeIndex {
            if (episodesArray.count > currentEpisodeIndex) {
                return Array(episodesArray[0...currentEpisodeIndex])
            }
        }
        if (episodesArray.count > 2) {
            return Array(episodesArray[0...2])
        } else {
            return episodesArray
        }
    }
    
    var currentEpisodeIndex: Int? {
        get {
            return episodesArray.firstIndex(where: { $0.itemID == currentEpisodeId })
        }
    }
    
    var nextEpisodeIndex: Int {
        get {
            let currentEId = currentEpisodeId
            
            if let currentIndex = episodesArray.firstIndex(where: { $0.itemID == currentEId }) {
                if currentIndex > 0 {
                    return currentIndex - 1
                } else {
                    return currentIndex
                }
            }
            
            return 0
        }
    }
    
    func getEpisodeInfo() -> (String, String) {
        let episode = getCurrentEpisode()
        
        return (episode?.title ?? "Episode with no title", episode?.imageURLPath ?? "")
    }
    
    func getEpisodeWith(id: String) -> PodcastEpisode? {
        return episodesArray.first(where: { $0.itemID == id })
    }
    
    func getIndexForEpisodeWith(id: String) -> Int? {
        return episodesArray.firstIndex(where: { $0.itemID == id })
    }
    
    func getEpisodeWith(index: Int) -> PodcastEpisode? {
        if episodesArray.count > index {
            return episodesArray[index]
        }
        return nil
    }
    
    func getItemRankForEpisodeWithId(id: String) -> Int {
        if !isRecommendationsPodcast { return 0 }
        
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
        comment.itemId = episode?.itemID
        comment.title = episode?.title
        comment.url = episode?.urlPath
        comment.timestamp = episode?.currentTime ?? 0
        
        return comment
    }
    
}
