//
//  NewChatViewModel+AttachmentsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

extension NewChatViewModel: AttachmentsManagerDelegate {
    func insertPrivisionalAttachmentMessageAndUpload(
        attachmentObject: AttachmentObject,
        chat: Chat?
    ) {
        let attachmentsManager = AttachmentsManager.sharedInstance
        let replyingMessage = replyingTo
        
        chatDataSource?.setMediaDataForMessageWith(
            messageId: TransactionMessage.getProvisionalMessageId(),
            mediaData: MessageTableCellState.MediaData(
                image: attachmentObject.image,
                videoData: attachmentObject.data,
                fileInfo: attachmentObject.getFileInfo(),
                failed: false
            )
        )
        
        if let message = TransactionMessage.createProvisionalAttachmentMessage(
            attachmentObject: attachmentObject,
            date: Date(),
            chat: chat,
            replyUUID: replyingMessage?.uuid
        ) {
            attachmentsManager.setData(
                delegate: self,
                contact: contact,
                chat: chat,
                provisionalMessage: message
            )
            
            attachmentsManager.uploadAndSendAttachment(
                attachmentObject: attachmentObject,
                replyingMessage: replyingMessage
            )
        }
        
        resetReply()
    }
    
    func shouldReplaceMediaDataFor(provisionalMessageId: Int, and messageId: Int) {
        chatDataSource?.replaceMediaDataForMessageWith(
            provisionalMessageId: provisionalMessageId,
            toMessageWith: messageId
        )
    }
    
    func didFailSendingMessage(
        provisionalMessage: TransactionMessage?
    ) {
        if let provisionalMessage = provisionalMessage {
            CoreDataManager.sharedManager.deleteObject(object: provisionalMessage)
            
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        }
    }
    
    func didUpdateUploadProgressFor(messageId: Int, progress: Int) {
        chatDataSource?.setProgressForProvisional(messageId: messageId, progress: progress)
    }
    
    func didSuccessSendingAttachment(message: TransactionMessage, image: UIImage?) {
        insertSentMessage(
            message: message,
            completion: { _ in }
        )
    }
}
