//
//  NewChatTableDataSource+AttachmentsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func setMediaForProvisional(
        messageId: Int,
        with attachmentObject: AttachmentObject
    ) {
        cachedMedia[messageId] = MessageTableCellState.MediaData(
            image: attachmentObject.image,
            videoData: attachmentObject.data,
            fileInfo: attachmentObject.getFileInfo(),
            failed: false
        )
    }
    
    func resetMediaForProvisional(
        messageId: Int
    ) {
        cachedMedia.removeValue(forKey: messageId)
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
