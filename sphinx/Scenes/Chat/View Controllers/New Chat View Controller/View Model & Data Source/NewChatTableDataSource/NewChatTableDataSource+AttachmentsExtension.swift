//
//  NewChatTableDataSource+AttachmentsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func setMediaDataForMessageWith(
        messageId: Int,
        mediaData: MessageTableCellState.MediaData
    ) {
        cachedMedia[messageId] = mediaData
    }
    
    func resetMediaForProvisional(
        messageId: Int
    ) {
        cachedMedia.removeValue(forKey: messageId)
    }
    
    func replaceMediaDataForMessageWith(
        provisionalMessageId: Int,
        toMessageWith messageId: Int
    ) {
        if let mediaData = cachedMedia[provisionalMessageId] {
            cachedMedia[messageId] = mediaData
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
