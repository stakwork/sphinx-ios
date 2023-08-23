//
//  NewChatViewController+SearchMessagesExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController {
    func toggleSearchMode(active: Bool) {
        SoundsPlayer.playHaptic()
        
        viewMode = active ? ViewMode.Search : ViewMode.Standard
        
        bottomView.configureSearchWith(
            active: active,
            loading: false,
            matchesCount: 0
        )
        
        headerView.configureSearchMode(
            active: active
        )
    }
}

extension NewChatViewController : ChatSearchTextFieldViewDelegate {
    func shouldSearchFor(term: String) {
        bottomView.configureSearchWith(
            active: true,
            loading: true
        )
        
        chatTableDataSource?.shouldSearchFor(term: term)
    }
    
    func didTapSearchCancelButton() {
        chatTableDataSource?.shouldEndSearch()
        toggleSearchMode(active: false)
    }
}

extension NewChatViewController : ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(
        button: ChatSearchResultsBar.NavigateArrowButton
    ) {
        chatTableDataSource?.shouldNavigateOnSearchResultsWith(button: button)
    }
}

extension NewChatViewController {
    func didFinishSearchingWith(
        matchesCount: Int,
        index: Int
    ) {
        bottomView.configureSearchWith(
            active: true,
            loading: false,
            matchesCount: matchesCount,
            matchIndex: index
        )
    }
    
    func shouldToggleSearchLoadingWheel(active: Bool) {
        bottomView.shouldToggleSearchLoadingWheel(active: active)
    }
}
