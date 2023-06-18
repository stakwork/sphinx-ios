//
//  NewChatViewController+BottomViewDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController : ChatMessageTextFieldViewDelegate {
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ()) {
        chatViewModel.shouldSendMessage(text: text, type: type, completion: { success in
            
            if success {
                self.bottomView.resetReplyView()
                self.scrollToBottomAfterSend()
            }
            
            completion(success)
        })
    }
    
    func scrollToBottomAfterSend() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            self.chatTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        })
    }
    
    func didTapAttachmentsButton(text: String?) {
        if AttachmentsManager.sharedInstance.uploading || self.presentedViewController != nil {
            return
        }
        
        let viewController = ChatAttachmentViewController.instantiate(
            delegate: self,
            chatId: self.chat?.id,
            text: text,
            replyingMessageId: nil
        )
        
        viewController.modalPresentationStyle = .overCurrentContext
        
        self.present(
            viewController,
            animated: false
        )
    }
    
    func shouldStartRecording() {
        
    }
    
    func shouldStopAndSendAudio() {
        
    }
    
    func shouldCancelRecording() {
        
    }
}

extension NewChatViewController : MessageReplyViewDelegate {
    func didCloseView() {
        chatViewModel.resetReply()
        shouldAdjustTableViewTopInset()
    }
    
    func shouldScrollTo(message: TransactionMessage) {}
}
