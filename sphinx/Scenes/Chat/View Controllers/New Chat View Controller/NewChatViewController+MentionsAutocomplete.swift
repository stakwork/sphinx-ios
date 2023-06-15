//
//  NewChatViewController+MentionsAutocomplete.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController: ChatMentionAutocompleteDelegate {
    
    func configureMentions() {
        chat?.processAliases()
        configureMentionAutocompleteTableView()
    }
    
    func didDetectPossibleMention(
        mentionText: String
    ) {
        guard let mentionsDataSource = chatMentionAutocompleteDataSource else {
            return
        }
        
        var possibleMentions = chatViewModel.getMentionsFrom(mentionText: mentionText)
        mentionsDataSource.updateMentionSuggestions(suggestions: possibleMentions)
    }
    
    func configureMentionAutocompleteTableView() {
        mentionsAutocompleteTableView.isHidden = true
        
        chatMentionAutocompleteDataSource = ChatMentionAutocompleteDataSource(
            tableView: mentionsAutocompleteTableView,
            delegate: self
        )
        
        mentionsAutocompleteTableView.delegate = chatMentionAutocompleteDataSource
        mentionsAutocompleteTableView.dataSource = chatMentionAutocompleteDataSource
    }
    
    func processAutocomplete(text: String) {
        bottomView.populateMentionAutocomplete(mention: text)
    }
}
