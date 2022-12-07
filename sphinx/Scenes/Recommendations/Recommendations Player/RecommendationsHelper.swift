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
            episode.title = item.itemTitle
            episode.episodeDescription = item.itemDescription
            episode.datePublished = Date(timeIntervalSince1970: TimeInterval(item.date ?? 0))
            episode.dateUpdated = Date(timeIntervalSince1970: TimeInterval(item.date ?? 0))
            episode.urlPath = item.link
            episode.imageURLPath = item.mediumImageUrl ?? item.smallImageUrl
            episode.linkURLPath = item.link
            episode.feed = podcast
            episode.type = item.type
            
            episodes.append(episode)
        }
        
        podcast.episodes = episodes
        
        if !podcastPlayerHelper.isPlaying(podcast.feedID) {
            let _ = podcastPlayerHelper.setNewEpisodeWith(episodeId: selectedItem.id, in: podcast)
        }
        podcastPlayerHelper.recommendationsPodcast = podcast
        
        return podcast
    }
}
