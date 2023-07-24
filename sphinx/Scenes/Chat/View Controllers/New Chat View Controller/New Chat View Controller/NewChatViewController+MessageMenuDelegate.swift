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
    
    func shouldDeleteMessage(message: TransactionMessage) {
        chatViewModel.shouldDeleteMessage(message: message)
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        chatViewModel.replyingTo = message
        bottomView.configureReplyViewFor(message: message, withDelegate: self)
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
}

extension NewChatViewController: ThreadHeaderViewDelegate{
    func didTapShowMore() {
        headerView.threadHeaderView.isExpanded = true
        headerView.threadHeaderView.adjustNumberOfLines()
    }
    
    func didTapTextField() {
        headerView.threadHeaderView.isExpanded = false
        headerView.threadHeaderView.adjustNumberOfLines()
    }

}
