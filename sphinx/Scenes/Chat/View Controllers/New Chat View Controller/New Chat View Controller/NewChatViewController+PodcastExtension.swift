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
        
        PodcastNewEpisodeViewController.checkForNewEpisode(chatId: chat?.id)
        headerView.updateSatsEarnedOnHeader()
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
            boostDelegate: self,
            fromDashboard: false
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
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
//        guard let message = message, success else {
//            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
//                self.didFailSendingMessage(provisionalMessage: message)
//            })
//            return
//        }
//        self.insertSentMessage(message: message, completion: { _ in })
    }
}
