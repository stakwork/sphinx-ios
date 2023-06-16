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
            if textField.text?.isEmpty == true {
                presentFeedSearchView()
            }
        }
    }
    
    
    // The text field calls this method when it
    // is asked to resign the first responder status.
    func textFieldDidEndEditing(
        _ textField: UITextField,
        reason: UITextField.DidEndEditingReason
    ) {
        if case .feed = activeTab {
            if textField.text?.isEmpty == true {
                presentRootFeedsListView()
            }
        }
    }
    
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        
        return true
    }
    
    func getSearchFeedType() -> FeedType? {
        switch(feedsContainerViewController.activeFilterOption.id) {
        case DashboardFeedsContainerViewController.ContentFilterOption.listen.id:
            return FeedType.Podcast
        case DashboardFeedsContainerViewController.ContentFilterOption.watch.id:
            return FeedType.Video
        default:
            break
        }
        return nil
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch activeTab {
        case .feed:
            feedSearchResultsContainerViewController.updateSearchQuery(
                with: "",
                and: getSearchFeedType()
            )
            if (!textField.isEditing) {
                presentRootFeedsListView()
            }
        case .friends:
            contactsService.updateContactsSearchQuery(term: "")
        case .tribes:
            contactsService.updateChatsSearchQuery(term: "")
        }
        
        return true
    }
    
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let initialText = (textField.text ?? "") as NSString

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
                with: queryString,
                and: getSearchFeedType()
            )
        case .friends:
            contactsService.updateContactsSearchQuery(term: queryString)
        case .tribes:
            contactsService.updateChatsSearchQuery(term: queryString)
        }
            
        return true
    }
}


extension DashboardRootViewController {

    private func presentFeedSearchView() {
        feedViewMode = .searching
        
        feedsContainerViewController.removeFromParent()
        
        feedSearchResultsContainerViewController.feedType = getSearchFeedType()
        
        addChildVC(
            child: feedSearchResultsContainerViewController,
            container: mainContentContainerView
        )
    }
    
    
    private func presentRootFeedsListView() {
        feedViewMode = .rootList
        
        feedSearchResultsContainerViewController.removeFromParent()
        
        addChildVC(
            child: feedsContainerViewController,
            container: mainContentContainerView
        )
        
        actionsManager.saveFeedSearches()
    }
}
