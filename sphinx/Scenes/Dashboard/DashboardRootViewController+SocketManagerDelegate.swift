// DashboardRootViewController+SocketManagerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData(shouldForceReload: true, shouldAnimateChanges: true)
    }
    
    
    func didReceiveConfirmation(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData(shouldForceReload: true, shouldAnimateChanges: true)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData(shouldForceReload: true, shouldAnimateChanges: true)
    }
    
    
    func didUpdateContact(contact: UserContact) {
        updateCurrentViewControllerData(shouldForceReload: true, shouldAnimateChanges: true)
    }
    
    func didUpdateChat(chat: Chat) {
        updateCurrentViewControllerData(shouldForceReload: true, shouldAnimateChanges: true)
    }
    
    
    func didReceiveOrUpdateGroup() {
        loadContactsAndSyncMessages()
    }
}
