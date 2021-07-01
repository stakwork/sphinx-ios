//
//  Library
//
//  Created by Tomas Timinskas on 18/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

extension ChatListViewController {
    func configureHeader() {
        headerView.delegate = self
        
        searchBarContainer.addShadow(location: VerticalLocation.bottom, opacity: 0.15, radius: 3.0)
        bottomBarContainer.addShadow(location: VerticalLocation.top, opacity: 0.2, radius: 3.0)

        searchBar.layer.borderColor = UIColor.Sphinx.Divider.resolvedCGColor(with: self.view)
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = searchBar.frame.height / 2
    }
    
    func listenForEvents() {
        headerView.listenForEvents()
        
        NotificationCenter.default.addObserver(forName: .onGroupDeleted, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.initialLoad()
        }
    }
    
    func resetSearchField() {
        searchTextField?.text = ""
    }
}

extension ChatListViewController : SocketManagerDelegate {
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        updateContactsAndReload(shouldReload: shouldSync)
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
        updateContactsAndReload(shouldReload: false)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        updateContactsAndReload(shouldReload: false)
    }
    
    func shouldShowAlert(message: String) {
        AlertHelper.showAlert(title: "Hey!", message: message)
    }
    
    func didUpdateContact(contact: UserContact) {
        chatListDataSource?.updateContactAndReload(object: contact)
    }
    
    func didUpdateChat(chat: Chat) {
        chatListDataSource?.updateChatAndReload(object: chat)
    }
    
    func didReceiveOrUpdateGroup() {
        loadFriendAndReload()
    }
}
