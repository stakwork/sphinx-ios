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
    
    private var recommendations: [RecommendationResult] = []
    
    func getSavedRecommendations() -> [RecommendationResult] {
        return self.recommendations
    }
    
    func persistRecommendations(
        _ recommendations: [RecommendationResult]
    ) {
        self.recommendations = recommendations
    }
    
    func getPodcastFor(
        recommendations: [RecommendationResult],
        selectedItem: RecommendationResult
    ) -> PodcastFeed {
        let podcastPlayerHelper = PodcastPlayerHelper.sharedInstance
        let podcast = PodcastFeed(nil, RecommendationsHelper.kRecommendationPodcastId, false)
        
        podcast.title = RecommendationsHelper.kRecommendationTitle
        podcast.podcastDescription = RecommendationsHelper.kRecommendationDescription
        
        var episodes: [PodcastEpisode] = []
        
        for item in recommendations {
            let episode = PodcastEpisode(nil, item.id)
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
            episode.topics = selectedItem.topics
            episode.showTitle = item.showTitle
            
            episodes.append(episode)
        }
        
        podcast.episodes = episodes
        
        podcastPlayerHelper.recommendationsPodcast = podcast
        
        return podcast
    }
}
