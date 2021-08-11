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
        }
    }
    
    
    func didReceiveConfirmation(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        chatsListViewModel.updateContactsAndChats()
    }
    
    
    func didUpdateContact(contact: UserContact) {
        if activeTab == .friends {
            contactChatsContainerViewController.chats = chatsListViewModel.contactChats
        } else if activeTab == .tribes {
            tribeChatsContainerViewController.chats = chatsListViewModel.tribeChats
        }
    }
    
    func didUpdateChat(chat: Chat) {
        if activeTab == .friends {
            contactChatsContainerViewController.chats = chatsListViewModel.contactChats
        } else if activeTab == .tribes {
            tribeChatsContainerViewController.chats = chatsListViewModel.tribeChats
        }
    }
    
    
    func didReceiveOrUpdateGroup() {
        loadContactsAndSyncMessages()
    }
}
