// DashboardRootViewController+UITextFieldDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    

// `UITextFieldDelegate` for handling search input


import UIKit


extension DashboardRootViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if case .feed = activeTab {
        /**
             - swap list view with an empty state view stating "Search over 4 000 000 podcasts on the Podcast Index"
         */
            feedsListViewController.removeFromParent()
            
            addChildVC(
                child: feedSearchResultsViewController,
                container: mainContentContainerView
            )
        }
    }
    
    
    // The text field calls this method when it
    // is asked to resign the first responder status.
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if case .feed = activeTab {
        /**
             - swap list view with an empty state view stating "Search over 4 000 000 podcasts on the Podcast Index"
         */
            feedSearchResultsViewController.removeFromParent()
            
            addChildVC(
                child: feedsListViewController,
                container: mainContentContainerView
            )
        }
    }
    
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        
        return true
    }
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch activeTab {
        case .feed:
            break
            // TODO: Clear search input
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
        var searchString = (textField.text ?? "") as NSString
    
        searchString = searchString.replacingCharacters(
            in: range,
            with: string
        ) as NSString
        

        switch activeTab {
        case .feed:
            feedSearchResultsViewController.updateSearchQuery(
                with: searchString as String
            )
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
}
