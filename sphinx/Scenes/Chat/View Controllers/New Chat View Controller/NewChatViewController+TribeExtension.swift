//
//  NewChatViewController+FeedExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController {
    func fetchTribeData() {
        chat?.updateTribeInfo() {
            self.headerView.setChatInfoOnHeader()
            self.loadPodcastFeed()
            self.configurePinnedMessageView()
        }
    }
    
    func showPendingApprovalMessage() {
        if chat?.isStatusPending() ?? false {
            NewMessageBubbleHelper().showGenericMessageView(text: "waiting.admin.approval".localized)
        }
    }
    
    ///Podcast
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
        
        PodcastNewEpisodeViewController.checkForNewEpisode(chatId: chat?.id)
        headerView.updateSatsEarnedOnHeader()
    }
    
    ///Pinned Message
    func configurePinnedMessageView() {
        if let chatId = chat?.id {
            headerView.configurePinnedMessageViewWith(
                chatId: chatId,
                andDelegate: self
            )
        }
    }
}

extension NewChatViewController : PodcastPlayerVCDelegate {
    func willDismissPlayer() {
        
    }
    
    func shouldShareClip(comment: PodcastComment) {
        
    }
    
    func shouldGoToPlayer(podcast: PodcastFeed) {
        
    }
    
    func didFailPlayingPodcast() {
        
    }
}

extension NewChatViewController : PinnedMessageViewDelegate {
    func didTapUnpinButtonFor(messageId: Int) {
        
    }
}
