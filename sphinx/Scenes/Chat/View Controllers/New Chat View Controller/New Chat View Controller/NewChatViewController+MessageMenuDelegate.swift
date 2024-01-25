//
//  NewChatViewController+MessageMenuDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatViewController : MessageOptionsVCDelegate {
     
    
    func shouldShowThreadFor(message: TransactionMessage) {
        if let threadUUID = message.threadUUID {
            self.showThread(threadID: threadUUID)
        } else if let uuid = message.uuid {
            self.showThread(threadID: uuid)
        }
    }
    
    func shouldReloadThreadHeaderView() {
        (chatTableDataSource as? ThreadTableDataSource)?.toggleHeader()
    }
    
    func shouldDeleteMessage(message: TransactionMessage) {
        chatViewModel.shouldDeleteMessage(message: message)
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        chatViewModel.replyingTo = message
        
        ChatTrackingHandler.shared.saveReplyableMessage(
            with: message.id,
            chatId: chat?.id
        )
        
        bottomView.configureReplyViewFor(
            message: message,
            withDelegate: self
        )
        
        shouldAdjustTableViewTopInset()
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        chatViewModel.shouldBoostMessage(message: message)
    }
    
    func shouldResendMessage(message: TransactionMessage) {
        chatViewModel.shouldResendMessage(message: message)
    }
    
    func shouldFlagMessage(message: TransactionMessage) {
        chatViewModel.sendFlagMessageFor(message)
    }
    
    func shouldReloadChat() {
        viewMode = ViewMode.Standard
        chatTableDataSource?.forceReload()
    }
    
    //Unused stubs:
    func shouldToggleReadUnread(chat: Chat) {}
}
