//
//  PodcastPlayerView+Delegates.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension PodcastPlayerView : PlayerDelegate {
    func loadingState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        
        configureControls(playing: true)
        showInfo()
        audioLoading = true
    }
    
    func playingState(_ podcastData: PodcastData) {
        if dragging {
            return
        }
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        podcast?.currentTime = podcastData.currentTime ?? 0
        
        delegate?.shouldReloadEpisodesTable()
        configureControls(playing: true)
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
        addMessagesFor(ts: podcastData.currentTime ?? 0)
        audioLoading = false
    }
    
    func pausedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        podcast?.currentTime = podcastData.currentTime ?? 0
        
        delegate?.shouldReloadEpisodesTable()
        configureControls(playing: false)
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
        audioLoading = false
    }
    
    func endedState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        podcast?.currentTime = 0
        
        configureControls(playing: false)
        setProgress(duration: podcastData.duration ?? 0, currentTime: podcastData.currentTime ?? 0)
    }
    
    func errorState(_ podcastData: PodcastData) {
        if podcastData.podcastId != podcast?.feedID {
            return
        }
        delegate?.didFailPlayingPodcast()
    }
}

extension CustomBoostViewDelegate{
    func didFailToBoost(message: String) {
        AlertHelper.showAlert(title: "Boost Failed", message: message)
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

extension PodcastPlayerView: CustomBoostViewDelegate {
    
    func didStartBoostAmountEdit() {
        self.boostDelegate?.didStartEditingBoostAmount?()
    }
    
    func didTouchBoostButton(withAmount amount: Int) {
        if let episode = podcast.getCurrentEpisode(),
           let objectID = episode.objectID {
            
            let itemID = episode.itemID
            let currentTime = podcast.getCurrentEpisode()?.currentTime ?? 0
            
            if let boostMessage = feedBoostHelper.getBoostMessage(itemID: itemID, amount: amount, currentTime: currentTime) {
                
                let podcastAnimationVC = PodcastAnimationViewController.instantiate(amount: amount)
                WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastAnimationVC)
                podcastAnimationVC.showBoostAnimation()
                
                feedBoostHelper.processPayment(itemID: itemID, amount: amount, currentTime: currentTime)
                
                feedBoostHelper.sendBoostMessage(
                    message: boostMessage,
                    itemObjectID: objectID,
                    amount: amount,
                    completion: { (message, success) in
                        self.boostDelegate?.didSendBoostMessage(success: success, message: message)
                    }
                )
            }
        }
    }
}
