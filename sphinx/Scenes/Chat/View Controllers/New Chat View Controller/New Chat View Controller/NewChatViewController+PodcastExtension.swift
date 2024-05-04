//
//  NewChatViewController+PodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController {
    func loadPodcastFeed() {
        guard let chat = chat else {
            return
        }
        
        if isThread {
            return
        }
        
        FeedLoaderHelper.loadPodcastFeedFor(chat: chat, callback: { podcast in
            self.addSmallPlayerFor(podcast)
        })
    }
    
    func addSmallPlayerFor(
        _ podcast: PodcastFeed
    ) {
        bottomView.configurePlayerWith(
            podcastId: podcast.feedID,
            delegate: self,
            andKey: PodcastDelegateKeys.ChatSmallPlayerBar.rawValue
        )
        
        shouldAdjustTableViewTopInset()
        headerView.updateSatsEarnedOnHeader()
        
        if let _ =  self.presentedViewController {
            ///Prevent showing new episode view if another VC is presented
            return
        }
        PodcastNewEpisodeViewController.checkForNewEpisode(chatId: chat?.id)
    }
}

extension NewChatViewController : PodcastPlayerVCDelegate {
    func willDismissPlayer() {}
    
    func shouldShareClip(comment: PodcastComment) {
        chatViewModel.podcastComment = comment
        
        bottomView.configureReplyViewFor(
            podcastComment: comment,
            withDelegate: self
        )
        
        shouldAdjustTableViewTopInset()
    }
    
    func shouldGoToPlayer(podcast: PodcastFeed) {
        presentPodcastPlayerFor(podcast)
    }
    
    func presentPodcastPlayerFor(
        _ podcast: PodcastFeed
    ) {
        FeedsManager.sharedInstance.restoreContentFeedStatusInBackgroundFor(feedId: podcast.feedID)

        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            podcast: podcast,
            delegate: self,
            boostDelegate: self
        )
        
        let navController = UINavigationController()
        
        navController.viewControllers = [podcastFeedVC]
        navController.modalPresentationStyle = .automatic
        navController.isNavigationBarHidden = true
        navigationController?.present(navController, animated: true)
    }
    
    func didFailPlayingPodcast() {
        let presentedVC = (presentedViewController as? UINavigationController)?
            .viewControllers.first ?? presentedViewController
        
        if let _ = presentedVC as? NewPodcastPlayerViewController {
            return
        }
        
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "error.playing".localized)
    }
}

extension NewChatViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {}
}
