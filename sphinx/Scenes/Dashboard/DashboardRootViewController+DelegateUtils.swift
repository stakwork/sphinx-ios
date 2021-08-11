import UIKit


// MARK: - `UITextFieldDelegate` for handling search input
extension DashboardRootViewController: UITextFieldDelegate {
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        
        return true
    }
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch activeTab {
        case .feed:
            break
        case .friends:
            contactChatsContainerViewController.chats = contactsService
                .getChatListObjects()
                .compactMap { $0 as? Chat }
        case .tribes:
            tribeChatsContainerViewController.chats = contactsService
                .getChatListObjects()
                .compactMap { $0 as? Chat }
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
            break
        case .friends:
            contactChatsContainerViewController.chats = contactsService
                .getChatsWith(searchString: searchString as String)
                .filter { $0.isConversation() }
        case .tribes:
            tribeChatsContainerViewController.chats = contactsService
                .getChatsWith(searchString: searchString as String)
                .filter { $0.isPublicGroup() }
        }
            
        return true
    }
}

// TODO: Is there going to be a place for adding new contacts / tribes on the friends and tribes tab views?
//extension DashboardRootViewController: NewContactVCDelegate {
//    func shouldReloadContacts(reload: Bool) {
//        if reload {
////            loadFriendAndReload()
//        }
//    }
//}


extension DashboardRootViewController: QRCodeScannerDelegate {
    func didScanDeepLink() {
        handleLinkQueries()
    }
}


extension DashboardRootViewController: WindowsManagerDelegate {

    func didDismissCoveringWindows() {
    }
}


extension DashboardRootViewController: PaymentInvoiceDelegate {

    func willDismissPresentedView(paymentCreated: Bool) {
        rootViewController.setStatusBarColor(light: true)
        headerView.updateBalance()
    }
}
