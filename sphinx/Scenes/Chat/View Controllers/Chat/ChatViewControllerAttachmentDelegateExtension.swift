//
//  ChatViewControllerAttachmentDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension ChatViewController : AttachmentsDelegate {
    func willDismissPresentedVC() {
        accessoryView.addKeyboardObservers()
        accessoryView.show()
    }
    
    func shouldStartUploading(attachmentObject: AttachmentObject) {
        accessoryView.clearMessage()
        accessoryView.togglePlaceHolder(editing: false)
        insertPrivisionalAttachmentMessageAndUpload(attachmentObject: attachmentObject, chat: chat)
    }
    
    func shouldSendGiphy(message: String) {
        let messageType = TransactionMessage.TransactionMessageType.message.rawValue
        shouldSendMessage(text: message, type: messageType, completion: { _ in })
    }
    
    func didTapSendButton() {
        accessoryView.hideReplyView()
        
        var viewController : UIViewController!

        if let chat = chat, chat.isPrivateGroup() {
            viewController = GroupPaymentViewController.instantiate(rootViewController: rootViewController, baseVC: self, viewModel: chatViewModel, chat: chat)
        } else {
            let mode: CreateInvoiceViewController.paymentMode = (chat?.isPublicGroup() ?? false) && (chat?.tribeInfo?.hasLoopoutBot ?? false) ? .sendOnchain : .send
            viewController = CreateInvoiceViewController.instantiate(contacts: getContacts(), chat: chat, viewModel: chatViewModel, delegate: self, paymentMode: mode, rootViewController: rootViewController)
        }
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func didTapReceiveButton() {
        accessoryView.hideReplyView()
        
        let viewController = CreateInvoiceViewController.instantiate(contacts: getContacts(), chat: chat, viewModel: chatViewModel, delegate: self, rootViewController: rootViewController)
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func didCloseReplyView() {
        accessoryView.hideReplyView()
    }
}

extension ChatViewController : AttachmentsManagerDelegate {
    func insertPrivisionalAttachmentMessageAndUpload(attachmentObject: AttachmentObject, chat: Chat?) {
        let attachmentsManager = AttachmentsManager.sharedInstance
        let replyingMessage = accessoryView.getReplyingMessage()
        
        if let message = TransactionMessage.createProvisionalAttachmentMessage(attachmentObject: attachmentObject, date: Date(), chat: chat, replyUUID: replyingMessage?.uuid) {
            chatDataSource?.addMessageAndReload(message: message, provisional: true)
            
            attachmentsManager.setData(delegate: self, contact: contact, chat: chat, provisionalMessage: message)
            attachmentsManager.uploadAndSendAttachment(attachmentObject: attachmentObject, replyingMessage: replyingMessage)
        }
        accessoryView.hideReplyView()
    }
    
    func didFailSendingMessage(provisionalMessage: TransactionMessage?) {
        if let provisionalMessage = provisionalMessage {            
            chatDataSource?.deleteCellFor(m: provisionalMessage)
            CoreDataManager.sharedManager.deleteObject(object: provisionalMessage)
            showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        }
        enableViewAndComplete(success: true, completion: { _ in })
    }
    
    func didUpdateUploadProgress(progress: Int) {
        for cell in chatTableView.visibleCells {
            if let cell = cell as? MediaUploadingCellProtocol, cell.isUploading() {
                cell.configureUploadingProgress(progress: progress, finishUpload: (progress >= 100))
            }
        }
    }
    
    func didSuccessSendingAttachment(message: TransactionMessage, image: UIImage?) {
        insertSentMessage(message: message, completion: { _ in })
    }
}
