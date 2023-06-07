//
//  MessagesPreloaderHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

class MessagesPreloaderHelper {
    
    class var sharedInstance : MessagesPreloaderHelper {
        struct Static {
            static let instance = MessagesPreloaderHelper()
        }
        return Static.instance
    }
    
    var chatMessages: [Int: [MessageTableCellState]] = [:]
    
    func add(
        messageStateArray: [MessageTableCellState],
        for chatId: Int
    ) {
        self.chatMessages[chatId] = messageStateArray
    }
    
    func getMessageStateArray(for chatId: Int) -> [MessageTableCellState]? {
        if let messageStateArray = chatMessages[chatId], messageStateArray.count > 0 {
            return messageStateArray
        }
        return nil
    }
}
