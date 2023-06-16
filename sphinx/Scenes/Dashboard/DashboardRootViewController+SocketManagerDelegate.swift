// DashboardRootViewController+SocketManagerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        ///Not needed anymore
    }    
    
    func didReceiveConfirmation(message: TransactionMessage) {
        ///Not needed anymore
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        ///Not needed anymore
    }
    
    func didUpdateContact(contact: UserContact) {
        ///Not needed anymore
    }
    
    func didUpdateChat(chat: Chat) {
        ///Not needed anymore
    }
    
    func didReceiveOrUpdateGroup() {
        ///Not needed anymore
    }
}
