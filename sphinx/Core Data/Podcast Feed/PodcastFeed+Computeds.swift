import Foundation


extension PodcastFeed {
    
    var episodesArray: [PodcastEpisode] {
        guard let episodes = episodes else { return [] }
        
        return Array(episodes)
    }
    
    
    var destinationsArray: [PodcastDestination] {
        guard let destinations = destinations else { return [] }
        
        return Array(destinations)
    }
}
