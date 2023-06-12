//
//  NewChatTableDataSource+PreloaderExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func restorePreloadedMessages() {
        if let messagesStateArray = preloaderHelper.getMessageStateArray(for: chat.id) {
            messageTableCellStateArray = messagesStateArray
            
            for messageState in messagesStateArray {
                if let messageId = messageState.message?.id, let tribeInfo = messageState.linkTribe?.1 {
                    tribeLinks[messageId] = tribeInfo
                }
            }
            
            updateSnapshot()
        }
    }
    
    func saveMessagesToPreloader() {
        preloaderHelper.add(
            messageStateArray: messageTableCellStateArray.subarray(size: 50),
            for: chat.id
        )
    }
}
