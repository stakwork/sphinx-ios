// DashboardRootViewController+UITextFieldDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


// `UITextFieldDelegate` for handling search input
extension DashboardRootViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if case .feed = activeTab {
            presentFeedSearchView()
        }
    }
    
    
    // The text field calls this method when it
    // is asked to resign the first responder status.
    func textFieldDidEndEditing(
        _ textField: UITextField,
        reason: UITextField.DidEndEditingReason
    ) {
    }
    
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        
        return true
    }
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch activeTab {
        case .feed:
            feedSearchResultsContainerViewController.updateSearchQuery(
                with: ""
            )
            presentRootFeedsListView()
        case .friends:
            contactChatsContainerViewController.updateWithNewChats(
                chatsListViewModel.contactChats
            )
        case .tribes:
            tribeChatsContainerViewController.updateWithNewChats(
                chatsListViewModel.tribeChats
            )
        }
        
        return true
    }
    
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        var initialText = (textField.text ?? "") as NSString

        let queryString = initialText.replacingCharacters(
            in: range,
            with: string
        )
        
        switch activeTab {
        case .feed:
            if feedViewMode == .rootList {
                presentFeedSearchView()
            }
            
            feedSearchResultsContainerViewController.updateSearchQuery(
                with: queryString
            )
        case .friends:
            contactChatsContainerViewController.updateWithNewChats(
                chatsListViewModel
                    .contactChats(fromSearchQuery: queryString)
            )
        case .tribes:
            tribeChatsContainerViewController.updateWithNewChats(
                chatsListViewModel
                    .tribeChats(fromSearchQuery: queryString)
            )
        }
            
        return true
    }
}


extension DashboardRootViewController {

    private func presentFeedSearchView() {
        feedViewMode = .searching
        
        feedsListViewController.removeFromParent()
        
        addChildVC(
            child: feedSearchResultsContainerViewController,
            container: mainContentContainerView
        )
    }
    
    
    private func presentRootFeedsListView() {
        feedViewMode = .rootList
        
        feedSearchResultsContainerViewController.removeFromParent()
        
        addChildVC(
            child: feedsListViewController,
            container: mainContentContainerView
        )
    }
}
