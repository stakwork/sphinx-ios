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
            performSearch(
                term: searchTerm,
                itemsCount: max(500, self.messagesArray.count)
            )
        } else {
            
            if searchTerm.count > 0 {
                messageBubbleHelper.showGenericMessageView(text: "Search term must be longer than 3 characters")
            }
            
            resetResults()
        }
    }
    
    func performSearch(
        term: String,
        itemsCount: Int
    ) {
        guard let chat = chat else {
            return
        }
        
        let isNewSearch = searchingTerm != term
        
        searchingTerm = term
        
        if (itemsCount > self.messagesArray.count) {
            ///Start listening with this limit to prevent scroll jump on search cancel
            ///If listening was set with lower count, then on cancel could jump since less items are available
            self.configureResultsController(items: itemsCount)
        }
        if (itemsCount > self.messagesArray.count || isNewSearch) {
            ///Process messages if loading more items or doing a new search
            self.messagesArray = TransactionMessage.getAllMessagesFor(chat: chat, limit: itemsCount).reversed()
            self.processMessages(messages: self.messagesArray)
            self.isLastSearchPage = self.messagesArray.count < itemsCount
        }
    }
    
    func resetResults() {
        searchingTerm = nil
        searchMatches = []
        currentSearchMatchIndex = 0
        
        delegate?.didFinishSearchingWith(
            matchesCount: 0,
            index: currentSearchMatchIndex
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
        
        if message.isBotHTMLResponse() || message.isPayment() || message.isInvoice() || message.isDeleted() || message.isFlagged() {
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
        
        ///Invert indexes
        let itemsCount = messageTableCellStateArray.count
        
        for (index, indexAndMessageTableCellState) in searchMatches.enumerated() {
            searchMatches[index] = (
                itemsCount - indexAndMessageTableCellState.0 - 1,
                indexAndMessageTableCellState.1
            )
        }
        
        searchMatches = searchMatches.reversed()
        
        ///should scroll to first results after current scroll position
        currentSearchMatchIndex = searchMatches.firstIndex(
            where: { $0.0 >= (tableView.indexPathsForVisibleRows?.first?.row ?? 0) }
        ) ?? 0
        
        ///Show search results
        DispatchQueue.main.async {
            self.delegate?.didFinishSearchingWith(
                matchesCount: self.searchMatches.count,
                index: self.currentSearchMatchIndex
            )
            
            self.reloadAllVisibleRows()
            self.scrollToSearchAt(index: self.currentSearchMatchIndex)
        }
    }

    func scrollToSearchAt(index: Int) {
        if searchMatches.count > index && index >= 0 {
            let searchMatchIndex = searchMatches[index].0
            
            tableView.scrollToRow(
                at: IndexPath(row: searchMatchIndex, section: 0),
                at: .top,
                animated: true
            )
            
            if index + 1 == searchMatches.count {
                loadMoreItemForSearch()
            }
        }
    }
    
    func loadMoreItemForSearch() {
        if isLastSearchPage {
            return
        }
        
        delegate?.shouldToggleSearchLoadingWheel(active: true)
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            self.performSearch(
                term: self.searchingTerm ?? "",
                itemsCount: self.messagesArray.count + 500
            )
        })
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
