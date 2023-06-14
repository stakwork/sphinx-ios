//
//  NewChatViewModel.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

class NewChatViewModel: NSObject {
    
    func toggleVolumeOn(
        chat: Chat,
        completion: @escaping (Chat?) -> ()
    ) {
        let currentMode = chat.isMuted()
        
        API.sharedInstance.toggleChatSound(chatId: chat.id, muted: !currentMode, callback: { chatJson in
            if let updatedChat = Chat.insertChat(chat: chatJson) {
                completion(updatedChat)
            }
        }, errorCallback: {
            completion(nil)
        })
    }
    
}
