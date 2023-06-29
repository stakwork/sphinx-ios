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
        self.macros = [
            MentionOrMacroItem(type: .macro, displayText: "find.and.share.gif".localized,
                    image: #imageLiteral(resourceName: "giphy"),
                    action: {
                        self.shouldStartGiphy()
               }),
               MentionOrMacroItem(type: .macro, displayText: "start.audio.call".localized,
                image: #imageLiteral(resourceName: "phone_call_icon"),
                action: {
                    let time = Date.timeIntervalSinceReferenceDate
                    let room = "\(API.kVideoCallServer)\(TransactionMessage.kCallRoomName).\(time)"
                    let link = room + "#config.startAudioOnly=true"
                    self.chatViewModel.sendCallMessage(link: link)
                    self.bottomView.messageFieldView.shouldDismissKeyboard()
               }),
               MentionOrMacroItem(type: .macro, displayText: "start.video.call".localized,
                image: #imageLiteral(resourceName:"video_call_icon"),
                action: {
                    let time = Date.timeIntervalSinceReferenceDate
                    let link = "\(API.kVideoCallServer)\(TransactionMessage.kCallRoomName).\(time)"
                    self.chatViewModel.sendCallMessage(link: link)
                    self.bottomView.messageFieldView.shouldDismissKeyboard()
               }),
           ]
        
        if self.chat?.isGroup() == false{
            macros.append(contentsOf: [
                MentionOrMacroItem(type: .macro, displayText: "pub.key.options-send.payment".localized,
                 image: #imageLiteral(resourceName: "invoice-pay-button")
                 ,action: {
                     self.didTapSendButton()
                }),
                MentionOrMacroItem(type: .macro, displayText: "request.payment.create.invoice".localized,
                 image: #imageLiteral(resourceName: "invoice-receive-icon"),
                 action: {
                     self.didTapReceiveButton()
                })
            ])
        }
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
        var possibleMacros = (macrosText != "") ? self.macros.compactMap({$0.displayText}).filter(
        {
            let actionText = $0.lowercased()
            return actionText.contains(macrosText.lowercased()) || macrosText == ""
        }).sorted()
        :
        self.macros.compactMap({$0.displayText})

        localMacros  = macros.filter({macroObject in
            return possibleMacros.contains(macroObject.displayText)
        })
        if(chatMentionAutocompleteDataSource?.mentionSuggestions.count == 0){
            chatMentionAutocompleteDataSource?.updateMacroSuggestions(macros: localMacros)
        }
    }
    
    func configureMentionAutocompleteTableView() {
        mentionsAutocompleteTableView.isHidden = true
        
        chatMentionAutocompleteDataSource = ChatMentionAutocompleteDataSource(
            tableView: mentionsAutocompleteTableView,
            delegate: self, chat: self.chat, macros: self.macros
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
