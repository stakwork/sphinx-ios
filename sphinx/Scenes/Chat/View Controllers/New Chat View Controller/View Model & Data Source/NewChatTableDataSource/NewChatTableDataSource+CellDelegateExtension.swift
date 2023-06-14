//
//  NewChatTableDataSource+CellDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

///Loading content in background
extension NewChatTableDataSource : NewMessageTableViewCellDelegate {
    func shouldLoadTribeInfoFor(
        link: String,
        with messageId: Int,
        and rowIndex: Int
    ) {
        if var tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: link) {
            API.sharedInstance.getTribeInfo(host: tribeInfo.host, uuid: tribeInfo.uuid, callback: { groupInfo in
                
                GroupsManager.sharedInstance.update(tribeInfo: &tribeInfo, from: groupInfo)
                
                self.updateMessageTableCellStateFor(
                    rowIndex: rowIndex,
                    messageId: messageId,
                    with: tribeInfo
                )
                
            }, errorCallback: {})
        }
    }
    
    func updateMessageTableCellStateFor(
        rowIndex: Int,
        messageId: Int,
        with tribeInfo: GroupsManager.TribeInfo
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let linkTribe = tableCellState.1.linkTribe
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
    
    func shouldLoadImageDataFor(
        url: URL?,
        with messageId: Int,
        and rowIndex: Int
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message, let imageUrl = url
        {
            MediaLoader.loadImage(url: imageUrl, message: message, completion: { messageId, image in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: image
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func shouldLoadPdfDataFor(
        url: URL?,
        with messageId: Int,
        and rowIndex: Int
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message, let url = url
        {
            MediaLoader.loadPDFData(url: url, message: message, completion: { (messageId, data, fileInfo) in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: fileInfo.previewImage,
                    fileInfo: fileInfo
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func shouldLoadVideoDataFor(
        url: URL?,
        with messageId: Int,
        and rowIndex: Int
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message, let url = url
        {
            MediaLoader.loadVideo(url: url, message: message, completion: { (messageId, data, image) in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: image
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func updateMessageTableCellStateFor(
        rowIndex: Int,
        messageId: Int,
        with updatedMediaData: MessageTableCellState.MediaData
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            self.cachedMedia[messageId] = updatedMediaData
            tableCellState.1.mediaData = updatedMediaData
            self.messageTableCellStateArray[tableCellState.0] = tableCellState.1
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.updateSnapshot()
            })
        }
    }
}

///Actions handling
extension NewChatTableDataSource {
    func didTapMessageReplyFor(messageId: Int, and rowIndex: Int) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            if let messageReply = tableCellState.1.messageReply {
                if let replyingTableCellIndex = getTableCellStateFor(messageId: messageReply.messageId)?.0 {
                    tableView.scrollToRow(
                        at: IndexPath(row: replyingTableCellIndex, section: 0),
                        at: .top,
                        animated: true
                    )
                }
            }
        }
    }
}

extension NewChatTableDataSource {
    func getTableCellStateFor(
        messageId: Int,
        and rowIndex: Int? = nil
    ) -> (Int, MessageTableCellState)? {
        
        var tableCellState: (Int, MessageTableCellState)? = nil
        
        if let rowIndex = rowIndex, messageTableCellStateArray[rowIndex].message?.id == messageId {
            return (rowIndex, messageTableCellStateArray[rowIndex])
        }
        
        for i in 0..<messageTableCellStateArray.count {
            if messageTableCellStateArray[i].message?.id == messageId {
                tableCellState = (i, messageTableCellStateArray[i])
                break
            }
        }
        
        return tableCellState
    }
}
