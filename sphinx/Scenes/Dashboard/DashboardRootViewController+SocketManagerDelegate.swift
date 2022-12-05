// DashboardRootViewController+SocketManagerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        chatsListViewModel.updateContactsAndChats()
        updateCurrentViewControllerData()
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
