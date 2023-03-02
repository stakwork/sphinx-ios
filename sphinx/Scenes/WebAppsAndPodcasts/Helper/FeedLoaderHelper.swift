//
//  FeedLoaderHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/03/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

class FeedLoaderHelper {
    
    class func loadPodcastFeedFor(
        chat: Chat,
        callback: @escaping (PodcastFeed) -> ()
    ) { 
        if let contentFeed = chat.contentFeed, contentFeed.isPodcast {
            let podcast = PodcastFeed.convertFrom(contentFeed: contentFeed)
            callback(podcast)
        }
    }
}
