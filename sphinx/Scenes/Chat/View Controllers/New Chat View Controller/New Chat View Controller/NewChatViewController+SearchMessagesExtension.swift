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
        bottomView.configureSearchWith(
            active: active
        )
        
        headerView.configureSearchMode(
            active: active
        )
    }
}

extension NewChatViewController : ChatSearchTextFieldViewDelegate {
    func shouldSearchFor(term: String) {
        
    }
    
    func didTapSearchCancelButton() {
        toggleSearchMode(active: false)
    }
}

extension NewChatViewController : ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton) {
        
    }
}
