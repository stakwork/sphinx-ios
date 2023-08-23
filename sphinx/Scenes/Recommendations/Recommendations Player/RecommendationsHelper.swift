//
//  RecommendationsHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

class RecommendationsHelper {
    
    class var sharedInstance : RecommendationsHelper {
        
        struct Static {
            static let instance = RecommendationsHelper()
        }
        
        return Static.instance
    }
    
    static let kRecommendationPodcastId = "Recommendations-Feed"
    static let kRecommendationTitle = "Recommendations"
    static let kRecommendationDescription = "Feed Recommendations"
    
    static let PODCAST_TYPE = "podcast"
    static let YOUTUBE_VIDEO_TYPE = "youtube"
    static let NEWSLETTER_TYPE = "newsletter"
    static let TWITTER_TYPE = "twitter_space"
    
    var recommendationsPodcast: PodcastFeed? = nil
    
    func getPodcastFor(
        recommendations: [RecommendationResult]
    ) -> PodcastFeed {
        let podcast = PodcastFeed(RecommendationsHelper.kRecommendationPodcastId, false)
        
        podcast.title = RecommendationsHelper.kRecommendationTitle
        podcast.podcastDescription = RecommendationsHelper.kRecommendationDescription
        
        var episodes: [PodcastEpisode] = []
        
        for item in recommendations {
            let episode = PodcastEpisode(item.id)
            episode.title = item.episodeTitle
            episode.episodeDescription = item.itemDescription
            
            if let date = item.date, date > 0 {
                episode.datePublished = Date(timeIntervalSince1970: TimeInterval(date))
                episode.dateUpdated = Date(timeIntervalSince1970: TimeInterval(date))
            } else {
                episode.datePublished = nil
                episode.dateUpdated = nil
            }
            
            episode.urlPath = item.link
            episode.imageURLPath = item.mediumImageUrl ?? item.smallImageUrl
            episode.linkURLPath = item.link
            episode.feed = podcast
            episode.type = item.type
            episode.clipStartTime = item.startSeconds
            episode.clipEndTime = item.endSeconds
            episode.people = item.guests
            episode.topics = item.topics
            episode.showTitle = item.showTitle
            
            if !item.pubKey.isEmpty && item.pubKey.isPubKey {
                let destination = PodcastDestination()
                destination.address = item.pubKey
                destination.split = 100
                destination.type = "node"
                
                episode.destination = destination
            }
            
            episodes.append(episode)
        }
        
        podcast.episodes = episodes
        
        recommendationsPodcast = podcast
        
        return podcast
    }
}
