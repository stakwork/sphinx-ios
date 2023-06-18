//
//  NewChatViewController+AttachmentsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController : AttachmentsDelegate {
    func willDismissPresentedVC() {}
    
    func shouldStartUploading(attachmentObject: AttachmentObject) {
//        accessoryView.clearMessage()
//        accessoryView.togglePlaceHolder(editing: false)
//        insertPrivisionalAttachmentMessageAndUpload(attachmentObject: attachmentObject, chat: chat)
    }
    
    func shouldSendGiphy(message: String) {
        chatViewModel.shouldSendMessage(
            text: message,
            type: TransactionMessage.TransactionMessageType.message.rawValue,
            completion: { _ in }
        )
    }
    
    func didTapSendButton() {
        let mode =
            (chat?.isPublicGroup() ?? false) && (chat?.tribeInfo?.hasLoopoutBot ?? false) ?
            PaymentsViewModel.PaymentMode.sendOnchain :
            PaymentsViewModel.PaymentMode.send

        let viewController = CreateInvoiceViewController.instantiate(
            contact: contact,
            chat: chat,
            delegate: self,
            paymentMode: mode
        )
        
        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func didTapReceiveButton() {
        messageBubbleHelper.showGenericMessageView(
            text: "Feature not implemented yet",
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.BadgeRed
        )
        
//        let viewController = CreateInvoiceViewController.instantiate(
//            contact: contact,
//            chat: chat,
//            delegate: self
//        )
//        self.presentNavigationControllerWith(vc: viewController)
    }
    
    func didCloseReplyView() {
        chatViewModel.resetReply()
        
        shouldAdjustTableViewTopInset()
        bottomView.resetReplyView()
    }
}

extension NewChatViewController : PaymentInvoiceDelegate {
    func didCreateMessage(message: TransactionMessage) {
        
    }
    
    func didFailCreatingInvoice() {
        
    }
    
    func shouldSendOnchain(address: String, amount: Int) {
        
    }
    
    func shouldSendTribePayment(
        amount: Int,
        message: String,
        messageUUID: String,
        callback: (() -> ())?
    ) {
        
    }
    
}
