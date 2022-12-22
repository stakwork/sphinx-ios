//
//  ChatViewControllerPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension ChatViewController : CustomBoostDelegate {
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        guard let message = message, success else {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.didFailSendingMessage(provisionalMessage: message)
            })
            return
        }
        self.insertSentMessage(message: message, completion: { _ in })
        self.scrollAfterInsert()
    }
}

extension ChatViewController : PodcastPlayerVCDelegate {
    func loadPodcastFeed() {
        guard let chat = chat else {
            return
        }
        
        FeedLoaderHelper.loadPodcastFeedFor(chat: chat, callback: { podcast in
            self.addSmallPlayerFor(podcast, completion: {
                PodcastNewEpisodeViewController.checkForNewEpisode(chat: chat, rootViewController: self.rootViewController)
            })
            self.chatHeaderView.updateSatsEarned()
        })
    }
    
    func shouldShareClip(comment: PodcastComment) {
        accessoryView.addKeyboardObservers()
        accessoryView.configureReplyFor(podcastComment: comment)
    }
    
    func shouldGoToPlayer(podcast: PodcastFeed) {
        presentPodcastPlayerFor(podcast)
    }
    
    func willDismissPlayer() {
        accessoryView.addKeyboardObservers()
        accessoryView.show(animated: false)
    }
    
    func addSmallPlayerFor(
        _ podcast: PodcastFeed,
        completion: @escaping () -> ()
    ) {
        accessoryView.configurePlayerViewWith(
            podcast: podcast,
            delegate: self,
            completion: completion
        )
    }
    
    func presentPodcastPlayerFor(
        _ podcast: PodcastFeed
    ) {
        accessoryView.hide()
        
        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            podcast: podcast,
            delegate: self,
            boostDelegate: self,
            fromDashboard: false
        )

        podcastFeedVC.modalPresentationStyle = .automatic

        present(podcastFeedVC, animated: true, completion: nil)
    }
}
