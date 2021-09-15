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
    
    
    var searchResultItem: PodcastFeedSearchResult {
        .init(
            id: Int(id),
            title: title ?? "",
            podcastDescription: podcastDescription ?? "",
            author: author ?? "",
            imageURLPath: imageURLPath,
            feedURLPath: feedURLPath
        )
    }
}



extension PodcastFeed {

    convenience init(
        from searchResult: PodcastFeedSearchResult,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.init(context: managedObjectContext)

        id = Int64(searchResult.id)
        title = searchResult.title
        podcastDescription = searchResult.podcastDescription
        author = searchResult.author
        imageURLPath = searchResult.imageURLPath
        feedURLPath = searchResult.feedURLPath
    }
}
