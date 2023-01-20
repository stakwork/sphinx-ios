//
//  PodcastPlayerController+ActionsTracking.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension PodcastPlayerController {
    func trackItemStarted(
        endTimestamp: Int? = nil
    ) {
        if let podcast = podcast,
            let episode = podcast.getCurrentEpisode() {
            
            actionsManager.trackItemStarted(
                item: episode,
                podcast: podcast,
                startTimestamp: podcast.currentTime,
                endTimestamp: endTimestamp
            )
        }
    }

    func trackItemFinished(
        shouldSaveAction: Bool = false
    ) {
        if let podcast = podcast,
            let episode = podcast.getCurrentEpisode() {
            
            actionsManager.trackItemFinished(
                item: episode,
                podcast: podcast,
                timestamp: podcast.currentTime,
                shouldSaveAction: shouldSaveAction
            )
        }
    }
    
    func finishAndSaveContentConsumed() {
        if !isPlaying {
            actionsManager.finishAndSaveContentConsumed()
        }
    }
}
