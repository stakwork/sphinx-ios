//
//  NewChatViewController+BottomViewDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController : ChatMessageTextFieldViewDelegate {
    func didChangeText(text: String) {
        ChatTrackingHandler.shared.saveOngoingMessage(with: text, chatId: chat?.id)
    }
    
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ()) {
        bottomView.resetReplyView()
        
        ChatTrackingHandler.shared.deleteReplyableMessage(with: chat?.id)
        
        chatViewModel.shouldSendMessage(text: text, type: type, completion: { success in
            
            if success {
                self.scrollToBottomAfterSend()
            }
            
            completion(success)
        })
    }
    
    func scrollToBottomAfterSend() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            if self.chatTableView.numberOfRows(inSection: 0) > 0 {
                self.chatTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        })
    }
    
    func didTapAttachmentsButton(text: String?) {
        if AttachmentsManager.sharedInstance.uploading || self.presentedViewController != nil {
            return
        }
        
        let viewController = getChatAttachmentVC(text:text)
        
        DispatchQueue.main.async {
            self.present(
                viewController,
                animated: false
            )
        }
    }
    
    func shouldStartRecording() {
        chatViewModel.shouldStartRecordingWith(delegate: self)
    }
    
    func shouldStopAndSendAudio() {
        chatViewModel.shouldStopAndSendAudio()
    }
    
    func shouldCancelRecording() {
        chatViewModel.shouldCancelRecording()
    }
    
    func shouldStartGiphy(){
        let vc = getChatAttachmentVC(text: nil)
        self.present(vc,animated:false)
        vc.presentGiphy()
    }
    
    func getChatAttachmentVC(
        text: String?
    ) -> ChatAttachmentViewController {
        
        let viewController = ChatAttachmentViewController.instantiate(
            delegate: self,
            chatId: chat?.id,
            text: text,
            replyingMessageId: chatViewModel.replyingTo?.id,
            isThread: isThread
        )
        
        viewController.modalPresentationStyle = .overCurrentContext
        return viewController
    }
}

extension NewChatViewController : AudioHelperDelegate {
    func didStartRecording(_ success: Bool) {
        if !success {
            messageBubbleHelper.showGenericMessageView(text: "microphone.permission.denied".localized, delay: 5)
        }
    }
    
    func didFinishRecording(_ success: Bool) {
        if success {
            bottomView.clearMessage()
            bottomView.resetReplyView()
            
            ChatTrackingHandler.shared.deleteReplyableMessage(with: chat?.id)
            
            chatViewModel.didFinishRecording()
        }
    }
    
    func audioTooShort() {
        let windowInset = getWindowInsets()
        let y = WindowsManager.getWindowHeight() - windowInset.bottom - bottomView.frame.size.height
        messageBubbleHelper.showAudioTooltip(y: y)
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        bottomView.updateRecordingAudio(minutes: minutes, seconds: seconds)
    }
}

extension NewChatViewController : MessageReplyViewDelegate {
    func didCloseView() {
        chatViewModel.resetReply()
        shouldAdjustTableViewTopInset()
        
        ChatTrackingHandler.shared.deleteReplyableMessage(with: chat?.id)
    }
    
    func shouldScrollTo(message: TransactionMessage) {}
}
