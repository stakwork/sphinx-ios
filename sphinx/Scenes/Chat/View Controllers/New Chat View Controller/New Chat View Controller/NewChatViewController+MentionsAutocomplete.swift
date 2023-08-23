//
//  NewChatViewController+MentionsAutocomplete.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController: ChatMentionAutocompleteDelegate {
    
    func initializeMacros() {
        if isThread {
            return
        }
        
        let isContactConversation = self.chat?.isGroup() == false
        
        self.macros = [
            MentionOrMacroItem(
                type: .macro,
                displayText: "send.giphy".localized,
                image: UIImage(named: "giphy"),
                imageContentMode: .scaleAspectFill,
                action: {
                    self.shouldStartGiphy()
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "start.audio.call".localized,
                icon: "call",
                action: {
                    self.shouldSendCallMessage(audioOnly: true)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "start.video.call".localized,
                icon: "video_call",
                action: {
                    self.shouldSendCallMessage(audioOnly: false)
               }
            )
        ]
        
        if isContactConversation {
            macros.append(contentsOf: [
                MentionOrMacroItem(
                    type: .macro,
                    displayText: "send.payment".localized,
                    image: UIImage(named: "payment-sent-arrow"),
                    imageContentMode: .center,
                    action: {
                        self.didTapSendButton()
                    }
                ),
                MentionOrMacroItem(
                    type: .macro,
                    displayText: "request.payment".localized,
                    image: UIImage(named: "payment-received-arrow"),
                    imageContentMode: .center,
                    action: {
                        self.didTapReceiveButton()
                    }
                )
            ])
        }
    }
    
    func shouldSendCallMessage(audioOnly: Bool) {
        let time = Date.timeIntervalSinceReferenceDate
        let room = "\(API.kVideoCallServer)\(TransactionMessage.kCallRoomName).\(time)"
        let link = audioOnly ? (room + "#config.startAudioOnly=true") : room
        self.chatViewModel.sendCallMessage(link: link)
        self.bottomView.messageFieldView.shouldDismissKeyboard()
    }
    
    func configureMentions() {
        configureMentionAutocompleteTableView()
    }
    
    func didDetectPossibleMention(
        mentionText: String
    ) {
        guard let mentionsDataSource = chatMentionAutocompleteDataSource else {
            return
        }
        
        let possibleMentions = chatViewModel.getMentionsFrom(mentionText: mentionText)
        mentionsDataSource.updateMentionSuggestions(suggestions: possibleMentions)
    }
    
    func didDetectPossibleMacro(macro: String) {
        var localMacros : [MentionOrMacroItem] = []
        let macrosText = String(macro).replacingOccurrences(of: "/", with: "").lowercased()
        
        let filteredMacros = macros.compactMap({$0.displayText}).filter({
            let actionText = $0.lowercased()
            return actionText.contains(macrosText.lowercased()) || macrosText == ""
        }).sorted()
        
        let possibleMacros = macrosText.isNotEmpty ? filteredMacros : macros.compactMap({$0.displayText})

        localMacros  = macros.filter({ macroObject in
            return possibleMacros.contains(macroObject.displayText)
        })
        
        if (chatMentionAutocompleteDataSource?.mentionSuggestions.count == 0) {
            chatMentionAutocompleteDataSource?.updateMacroSuggestions(macros: localMacros)
        }
    }
    
    func configureMentionAutocompleteTableView() {
        mentionsAutocompleteTableView.isHidden = true
        
        chatMentionAutocompleteDataSource = ChatMentionAutocompleteDataSource(
            tableView: mentionsAutocompleteTableView,
            delegate: self,
            chat: chat,
            macros: macros
        )
        
        mentionsAutocompleteTableView.delegate = chatMentionAutocompleteDataSource
        mentionsAutocompleteTableView.dataSource = chatMentionAutocompleteDataSource
    }
    
    func processAutocomplete(text: String) {
        bottomView.populateMentionAutocomplete(mention: text)
    }
    
    func processGeneralPurposeMacro(action: @escaping () -> ()) {
        action()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.chatMentionAutocompleteDataSource?.updateMacroSuggestions(macros: [])
            self.bottomView.clearMessage()
        })
    }
}
