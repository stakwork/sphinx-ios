//
//  Library
//
//  Created by Tomas Timinskas on 12/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

final class ChatViewModel: NSObject {
    
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
    
    func sendFlagMessageFor(_ message: TransactionMessage) {
        DispatchQueue.global().async {
            let supportContact = SignupHelper.getSupportContact()
            
            if let pubkey = supportContact["pubkey"].string {
                
                if let contact = UserContact.getContactWith(pubkey: pubkey) {
                    
                    let messageSender = message.getMessageSender()
                    
                    var flagMessageContent = """
                    Message Flagged
                    - Message: \(message.uuid ?? "Empty Message UUID")
                    - Sender: \(messageSender?.publicKey ?? "Empty Sender")
                    """
                    
                    if let chat = message.chat, chat.isPublicGroup() {
                        flagMessageContent = "\(flagMessageContent)\n- Tribe: \(chat.uuid ?? "Empty Tribe UUID")"
                    }
                    
                    self.sendFlagMessage(
                        contact: contact,
                        text: flagMessageContent
                    )
                    return
                }
            }
        }
    }
    
    func sendFlagMessage(
        contact: UserContact,
        text: String
    ) {
        guard let params = TransactionMessage.getMessageParams(
                contact: contact,
                type: TransactionMessage.TransactionMessageType.message,
                text: text
        ) else {
            return
        }
        
        API.sharedInstance.sendMessage(params: params, callback: { _ in }, errorCallback: {})
    }
}
