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
    
    func didTapSendBlueButton() {
        
    }
    
    func shouldStartRecording() {
        
    }
    
    func shouldStopAndSendAudio() {
        
    }
    
    func shouldCancelRecording() {
        
    }
}

extension NewChatViewController : AttachmentsDelegate {
    func willDismissPresentedVC() {
        
    }
    
    func shouldStartUploading(attachmentObject: AttachmentObject) {
        
    }
    
    func shouldSendGiphy(message: String) {
        
    }
    
    func didCloseReplyView() {
        
    }
    
    func didTapSendButton() {
        
    }
    
    func didTapReceiveButton() {
        
    }
}

extension NewChatViewController : MessageReplyViewDelegate {
    func didCloseView() {
        shouldAdjustTableViewTopInset()
    }
    
    func shouldScrollTo(message: TransactionMessage) {
//        chatDataSource?.scrollTo(message: message)
    }
}
