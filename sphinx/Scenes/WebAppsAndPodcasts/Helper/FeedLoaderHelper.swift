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
        
        guard chat.tribeInfo?.feedContentType?.isPodcast == true else {
            return
        }
        
        guard let _ = chat.tribeInfo?.feedUrl else {
            return
        }
        
        guard
            ConnectivityHelper.isConnectedToInternet,
            chat.tribeInfo?.feedUrl != nil
        else {
            if let feed = chat.contentFeed {
                let podcast = PodcastFeed.convertFrom(contentFeed: feed)
                callback(podcast)
            }
            return
        }
        
        if let contentFeed = chat.contentFeed {
            let podcast = PodcastFeed.convertFrom(contentFeed: contentFeed)
            callback(podcast)
        }
    }
}
