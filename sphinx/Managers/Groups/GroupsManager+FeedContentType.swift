//
//  GroupsManager+FeedContentType.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation

extension GroupsManager {
    
    enum FeedType: Int {
        case Podcast
        case Video
        case Newsletter
    }
    
    struct FeedContentType {
        
        let id: Int
        var description: String
        
        static var podcast: Self = .init(
            id: FeedType.Podcast.rawValue,
            description: "Podcast"
        )
        static var video: Self = .init(
            id: FeedType.Video.rawValue,
            description: "Video"
        )
        static var newsletter: Self = .init(
            id: FeedType.Newsletter.rawValue,
            description: "Newsletter"
        )
        
        static var allCases: [Self] {
            [
                .podcast,
                .video,
                .newsletter,
            ]
        }
        
        static var defaultValue: Self {
            .podcast
        }
        
        var isPodcast: Bool {
            return self.id == FeedType.Podcast.rawValue
        }
        
        var isVideo: Bool {
            return self.id == FeedType.Video.rawValue
        }
        
        var isNewsletter: Bool {
            return self.id == FeedType.Newsletter.rawValue
        }
    }
}
