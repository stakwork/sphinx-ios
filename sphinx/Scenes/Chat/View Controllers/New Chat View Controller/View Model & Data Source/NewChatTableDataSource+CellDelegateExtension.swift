//
//  NewChatTableDataSource+CellDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource : NewMessageTableViewCellDelegate {
    func shouldLoadTribeInfoFor(link: String, with messageId: Int) {
        if var tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: link) {
            API.sharedInstance.getTribeInfo(host: tribeInfo.host, uuid: tribeInfo.uuid, callback: { groupInfo in
                
                GroupsManager.sharedInstance.update(tribeInfo: &tribeInfo, from: groupInfo)
                
                self.updateMessageTableCellStateFor(
                    messageId: messageId,
                    with: tribeInfo
                )
                
            }, errorCallback: {})
        }
    }
    
    func updateMessageTableCellStateFor(
        messageId: Int,
        with tribeInfo: GroupsManager.TribeInfo
    ) {
        if var tableCellState = getTableCellStateFor(messageId: messageId),
            let linkTribe = tableCellState.1.linkTribe
        {    
            let updatedLinkTribe = MessageTableCellState.LinkTribe(
                link: linkTribe.link,
                tribeInfo: tribeInfo,
                isJoined: linkTribe.isJoined
            )
            
            self.tribeLinks[messageId] = updatedLinkTribe
            
            tableCellState.1.linkTribe = updatedLinkTribe
            
            messageTableCellStateArray[tableCellState.0] = tableCellState.1
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.updateSnapshot()
        })
    }
    
    func shouldLoadImageDataFor(url: URL?, with messageId: Int) {
        if let tableCellState = getTableCellStateFor(messageId: messageId),
           let message = tableCellState.1.message,
           let imageUrl = url
        {
            MediaLoader.loadImage(url: imageUrl, message: message, completion: { messageId, image in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: image
                )
                self.updateMessageTableCellStateFor(messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func shouldLoadPdfDataFor(url: URL?, with messageId: Int) {
        if let tableCellState = getTableCellStateFor(messageId: messageId),
           let message = tableCellState.1.message,
           let url = url
        {
            MediaLoader.loadPDFData(url: url, message: message, completion: { (messageId, data, fileInfo) in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: fileInfo.previewImage,
                    fileInfo: fileInfo
                )
                self.updateMessageTableCellStateFor(messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func shouldLoadVideoDataFor(url: URL?, with messageId: Int) {
        if let tableCellState = getTableCellStateFor(messageId: messageId),
           let message = tableCellState.1.message,
           let url = url
        {
            MediaLoader.loadVideo(url: url, message: message, completion: { (messageId, data, image) in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: image
                )
                self.updateMessageTableCellStateFor(messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func updateMessageTableCellStateFor(
        messageId: Int,
        with updatedMediaData: MessageTableCellState.MediaData
    ) {
        if var tableCellState = getTableCellStateFor(messageId: messageId)
        {
            self.cachedMedia[messageId] = updatedMediaData
            tableCellState.1.mediaData = updatedMediaData
            self.messageTableCellStateArray[tableCellState.0] = tableCellState.1
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.updateSnapshot()
            })
        }
    }
}

extension NewChatTableDataSource {
    func getTableCellStateFor(
        messageId: Int
    ) -> (Int, MessageTableCellState)? {
        
        var tableCellState: (Int, MessageTableCellState)? = nil
        
        for i in 0..<messageTableCellStateArray.count {
            if messageTableCellStateArray[i].message?.id == messageId {
                tableCellState = (i, messageTableCellStateArray[i])
                break
            }
        }
        
        return tableCellState
    }
}
