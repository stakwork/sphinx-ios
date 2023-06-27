//
//  NewChatTableDataSource+AttachmentsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func updateSnapshotWith(
        message: TransactionMessage
    ) {
        if messagesArray.isEmpty {
            processMessages(messages: [message])
        }
    }
}

extension NewChatTableDataSource {
    func setMediaDataForMessageWith(
        messageId: Int,
        mediaData: MessageTableCellState.MediaData
    ) {
        mediaCached[messageId] = mediaData
    }
    
    func resetMediaForProvisional(
        messageId: Int
    ) {
        mediaCached.removeValue(forKey: messageId)
    }
    
    func replaceMediaDataForMessageWith(
        provisionalMessageId: Int,
        toMessageWith messageId: Int
    ) {
        if let mediaData = mediaCached[provisionalMessageId] {
            mediaCached[messageId] = mediaData
        }
    }
    
    func setProgressForProvisional(
        messageId: Int,
        progress: Int
    ) {
        updateMessageTableCellStateFor(
            rowIndex: nil,
            messageId: messageId,
            with: MessageTableCellState.UploadProgressData(progress: progress)
        )
    }
    
    func resetProgressForProvisional(
        messageId: Int
    ) {
        uploadingProgress.removeValue(forKey: messageId)
    }
}
