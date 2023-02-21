// DashboardRootViewController+SocketManagerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: SocketManagerDelegate {
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        if message.shouldInitiateCallAlert,
           let chat = message.chat,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            let callerName = message.senderAlias ?? ("Caller from:\(message.chat?.name)")
            if #available(iOS 14.0, *) {
                JitsiIncomingCallManager.sharedInstance.currentJitsiURL = message.messageContent
            } else {
                // Fallback on earlier versions
            }
            appDelegate.handleIncomingCall(chatID:chat.id,callerName: callerName)
        }
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
