//
//  NewChatViewController+MessageMenuDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatViewController : MessageOptionsVCDelegate {
    func shouldDeleteMessage(message: TransactionMessage) {
        
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        chatViewModel.replyingTo = message
        bottomView.configureReplyViewFor(message: message, withDelegate: self)
        shouldAdjustTableViewTopInset()
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        
    }
    
    func shouldResendMessage(message: TransactionMessage) {
        
    }
    
    func shouldFlagMessage(message: TransactionMessage) {
        
    }
    
    func shouldRemoveWindow() {
        
    }
}
