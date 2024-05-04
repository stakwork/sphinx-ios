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
        configureMentions()
        
        if chat?.isPublicGroup() == false {
            return
        }
        
        chat?.updateTribeInfo() {
            self.headerView.setChatInfoOnHeader()
            self.loadPodcastFeed()
            self.configurePinnedMessageView()
            self.loadBadgesAndLeaderboard()
        }
    }
    
    func loadBadgesAndLeaderboard() {
        if isThread {
            return
        }
        
        self.chatViewModel.loadBadgesAndLeaderboard()
    }
    
    func showPendingApprovalMessage() {
        if chat?.isStatusPending() ?? false {
            messageBubbleHelper.showGenericMessageView(text: "waiting.admin.approval".localized)
        }
    }
    
    ///Pinned Message
    func configurePinnedMessageView() {
        if isThread {
            return
        }
        
        if let chatId = chat?.id {
            headerView.configurePinnedMessageViewWith(
                chatId: chatId,
                andDelegate: self
            ) {
                self.shouldAdjustTableViewTopInset()
            }
        }
    }
}

extension NewChatViewController : PinnedMessageViewDelegate, PinMessageDelegate {
    func didTapPinnedMessageButtonFor(messageId: Int) {
        showMessagePinnedInfo(messageId: messageId)
    }
    
    func didTapUnpinButton(message: TransactionMessage) {
        shouldTogglePinState(message: message, pin: false)
    }
    
    func shouldTogglePinState(message: TransactionMessage, pin: Bool) {
        guard let chat = self.chat else {
            return
        }
        
        API.sharedInstance.pinChatMessage(
            messageUUID: (pin ? message.uuid : "_"),
            chatId: chat.id,
            callback: { pinnedMessageUUID in
                self.chat?.pinnedMessageUUID = pinnedMessageUUID
                self.chat?.saveChat()
                
                self.configurePinnedMessageView()
                
                let vc = PinMessageViewController.instantiate(
                    messageId: message.id,
                    delegate: self,
                    mode: pin ? .MessagePinned : .MessageUnpinned
                )
                vc.modalPresentationStyle = .overCurrentContext
                self.present(vc, animated: false)
            },
            errorCallback: {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        )
    }
    
    func showMessagePinnedInfo(messageId: Int) {
        let vc = PinMessageViewController.instantiate(
            messageId: messageId,
            delegate: self,
            mode: .PinnedMessageInfo
        )
        
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: false)
    }
    
    func shouldNavigateTo(messageId: Int) {
        chatTableDataSource?.reloadWith(pinnedMessageId: messageId)
    }
}
