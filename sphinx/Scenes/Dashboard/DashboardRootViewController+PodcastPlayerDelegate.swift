//
//  DashboardRootViewController+PodcastPlayerDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/03/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

extension DashboardRootViewController : PlayerDelegate {
    func loadingState(_ podcastData: PodcastData) {}
    
    func playingState(_ podcastData: PodcastData) {
        podcastSmallPlayer.configureWith(podcastId: podcastData.podcastId, and: self)
        dismissibleBar.isHidden = false
    }
    
    func pausedState(_ podcastData: PodcastData) {}
    
    func endedState(_ podcastData: PodcastData) {}
    
    func errorState(_ podcastData: PodcastData) {}
    
    func hideSmallPodcastPlayer() {
        podcastSmallPlayer.isHidden = true
        dismissibleBar.isHidden = true
    }
}
