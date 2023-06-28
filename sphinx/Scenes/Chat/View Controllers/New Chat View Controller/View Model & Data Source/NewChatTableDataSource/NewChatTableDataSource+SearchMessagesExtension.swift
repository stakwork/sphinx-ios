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
            
            resetResults()
        }
    }
    
    func performSearch(term: String) {
        guard let chat = chat else {
            return
        }
        
        searchingTerm = term
        
        DispatchQueue.global(qos: .userInitiated).async {
            if self.messagesArray.count < 1000 {
                ///Start listening with this limit to prevent scroll jump on search cancel
                self.configureResultsController(items: 1000)
            }
            self.messagesArray = TransactionMessage.getAllMessagesFor(chat: chat, limit: 1000).reversed()
            self.processMessages(messages: self.messagesArray)
        }
    }
    
    func resetResults() {
        searchingTerm = nil
        searchMatches = []
        currentSearchMatchIndex = 0
        
        delegate?.didFinishSearchingWith(
            matchesCount: 0,
            index: 0
        )
        
        reloadAllVisibleRows()
    }
    
    func shouldEndSearch() {
        resetResults()
        forceReload()
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
                searchMatches.append(
                    (index, messageTableCellState)
                )
            }
        }
    }
    
    func startSearchProcess() {
        searchMatches = []
    }
    
    func finishSearchProcess() {
        guard let _ = searchingTerm else {
            return
        }
        
        let itemsCount = messageTableCellStateArray.count
        
        for (index, indexAndMessageTableCellState) in searchMatches.enumerated() {
            searchMatches[index] = (
                itemsCount - indexAndMessageTableCellState.0 - 1,
                indexAndMessageTableCellState.1
            )
        }
        
        searchMatches = searchMatches.reversed()
        
        DispatchQueue.main.async {
            self.delegate?.didFinishSearchingWith(
                matchesCount: self.searchMatches.count,
                index: 0
            )
            
            self.reloadAllVisibleRows()
            self.scrollToSearchAt(index: self.currentSearchMatchIndex)
        }
    }

    func scrollToSearchAt(index: Int) {
        if searchMatches.count > index {
            let searchMatchIndex = searchMatches[index].0
            
            tableView.scrollToRow(
                at: IndexPath(row: searchMatchIndex, section: 0),
                at: .top,
                animated: true
            )
        }
    }
    
    func reloadAllVisibleRows() {
        let tableCellStates = getTableCellStatesForVisibleRows()
        
        var snapshot = self.dataSource.snapshot()
        snapshot.reloadItems(tableCellStates)
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func shouldNavigateOnSearchResultsWith(
        button: ChatSearchResultsBar.NavigateArrowButton
    ) {
        switch(button) {
        case ChatSearchResultsBar.NavigateArrowButton.Up:
            currentSearchMatchIndex += 1
            break
        case ChatSearchResultsBar.NavigateArrowButton.Down:
            currentSearchMatchIndex -= 1
            break
        }
        
        scrollToSearchAt(index: currentSearchMatchIndex)
    }
}
