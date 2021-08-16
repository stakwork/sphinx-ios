// DashboardRootViewController+SocketManagerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData(shouldForceReload: true)
    }
    
    
    func didReceiveConfirmation(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData(shouldForceReload: true)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData(shouldForceReload: true)
    }
    
    
    func didUpdateContact(contact: UserContact) {
        updateCurrentViewControllerData(shouldForceReload: true)
    }
    
    func didUpdateChat(chat: Chat) {
        updateCurrentViewControllerData(shouldForceReload: true)
    }
    
    
    func didReceiveOrUpdateGroup() {
        loadContactsAndSyncMessages()
    }
}
