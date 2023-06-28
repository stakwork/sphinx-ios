//
//  NewChatTableDataSource+SearchMessagesExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func shouldSearchFor(term: String) {
        let searchTerm = term.trim()
        
        if searchTerm.isNotEmpty && searchTerm.count > 2 {
            performSearch(term: searchTerm)
        } else {
            
            if searchTerm.count > 0 {
                messageBubbleHelper.showGenericMessageView(text: "Search term must be longer than 3 characters")
            }
            
            searchingTerm = nil
            searchMatches = [:]
            
            self.delegate?.didFinishSearchingWith(
                matchesCount: 0,
                index: 0
            )
        }
    }
    
    func shouldEndSearch() {
        searchingTerm = nil
        searchMatches = [:]
        forceReload()
    }
    
    func performSearch(term: String) {
        guard let chat = chat else {
            return
        }
        
        searchingTerm = term
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.messagesArray = TransactionMessage.getAllMessagesFor(chat: chat, limit: 1000).reversed()
            self.processMessages(messages: self.messagesArray)
        }
    }
    
    func processForSearch(
        message: TransactionMessage,
        messageTableCellState: MessageTableCellState,
        index: Int
    ) {
        guard let searchingTerm = searchingTerm else {
            return
        }
        
        if message.isBotHTMLResponse() || message.isPayment() || message.isInvoice() {
            return
        }
        
        if let messageContent = message.bubbleMessageContentString, messageContent.isNotEmpty {
            if messageContent.lowercased().contains(searchingTerm.lowercased()) {
                searchMatches[index] = messageTableCellState
            }
        }
    }
    
    func finishSearchProcess() {
        guard let _ = searchingTerm else {
            return
        }
        
        let itemsCount = messageTableCellStateArray.count
        
        for (index, messageTableCellState) in searchMatches {
            searchMatches.removeValue(forKey: index)
            searchMatches[itemsCount - index - 1] = messageTableCellState
        }
        
        DispatchQueue.main.async {
            self.delegate?.didFinishSearchingWith(
                matchesCount: self.searchMatches.count,
                index: 0
            )
        }
    }
}
