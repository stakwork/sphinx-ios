// DashboardRootViewController+SocketManagerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: CustomSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: CustomSegmentedControl,
        to index: Int
    ) {
        activeTab = DashboardTab(rawValue: index)!
    }
}


extension DashboardRootViewController: ChatListHeaderDelegate {
    
    func leftMenuButtonTouched() {
        leftMenuDelegate?.shouldOpenLeftMenu()
    }
}



extension DashboardRootViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        if shouldSync {
            loadContactsAndSyncMessages()
        } else {
            chatsListViewModel.updateContactsAndChats()
            loadContactsAndSyncMessages()
        }
    }
    
    
    func didReceiveConfirmation(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
    }
    
    
    func didUpdateContact(contact: UserContact) {
        updateCurrentViewControllerData()
    }
    
    func didUpdateChat(chat: Chat) {
        updateCurrentViewControllerData()
    }
    
    
    func didReceiveOrUpdateGroup() {
        loadContactsAndSyncMessages()
    }
}
