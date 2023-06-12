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
                
                self.tribeLinks[messageId] = tribeInfo
                
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
        if var tableCellState = getTableCellStateFor(messageId: messageId), let linkTribe = tableCellState.1.linkTribe {
            tableCellState.1.linkTribe = (
                linkTribe.0,
                tribeInfo,
                linkTribe.2
            )
            
            messageTableCellStateArray[tableCellState.0] = tableCellState.1
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.updateSnapshot()
        })
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
