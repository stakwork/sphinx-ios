import Foundation


extension PodcastFeed {
    
    var episodesArray: [PodcastEpisode] {
        guard let episodes = episodes else { return [] }
        
        return Array(episodes)
    }
}
