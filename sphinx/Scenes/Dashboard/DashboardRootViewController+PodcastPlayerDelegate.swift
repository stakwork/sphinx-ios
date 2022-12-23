//
//  DashboardRootViewController+PodcastPlayerDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/03/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

extension DashboardRootViewController : PodcastPlayerDelegate {
    func playingState(podcastId: String, duration: Int, currentTime: Int) {
        if podcastSmallPlayer.configureWith(podcastId: podcastId, and: self) {
            loadingState(podcastId: podcastId, loading: false)
        }
        
        showSmallPodcastPlayer()
        podcastSmallPlayer.playingState(podcastId: podcastId, duration: duration, currentTime: currentTime)
    }
    
    func pausedState(podcastId: String, duration: Int, currentTime: Int) {
        podcastSmallPlayer.pausedState(podcastId: podcastId, duration: duration, currentTime: currentTime)
    }
    
    func loadingState(podcastId: String, loading: Bool) {
        podcastSmallPlayer.loadingState(podcastId: podcastId, loading: loading)
    }
    
    func errorState(podcastId: String) {
        podcastSmallPlayer.loadingState(podcastId: podcastId, loading: false)
    }
    
    func showSmallPodcastPlayer() {
        if podcastSmallPlayer.isHidden {
            podcastSmallPlayer.isHidden = false
            dismissibleBar.isHidden = false
        }
    }
    
    func hideSmallPodcastPlayer() {
        podcastSmallPlayer.isHidden = true
        dismissibleBar.isHidden = true
    }
}
