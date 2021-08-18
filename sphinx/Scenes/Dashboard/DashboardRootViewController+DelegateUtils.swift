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
            contactChatsContainerViewController.updateWithNewChats(
                contactsService
                    .getChatListObjects()
                    .compactMap { $0 as? Chat },
                shouldAnimateChanges: true,
                shouldForceReload: true
            )
        case .tribes:
            tribeChatsContainerViewController.updateWithNewChats(
                contactsService
                    .getChatListObjects()
                    .compactMap { $0 as? Chat },
                shouldAnimateChanges: true,
                shouldForceReload: true
            )
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
            contactChatsContainerViewController.updateWithNewChats(
                contactsService
                    .getChatsWith(searchString: searchString as String)
                    .filter { $0.isConversation() },
                shouldAnimateChanges: true,
                shouldForceReload: true
            )
        case .tribes:
            tribeChatsContainerViewController.updateWithNewChats(
                contactsService
                    .getChatsWith(searchString: searchString as String)
                    .filter { $0.isConversation() },
                shouldAnimateChanges: true,
                shouldForceReload: true
            )
        }
            
        return true
    }
}


extension DashboardRootViewController: QRCodeScannerDelegate {
    func didScanDeepLink() {
        handleLinkQueries()
    }
    
    
    func didScanQRCode(string: String) {
        print("QR Code Scanned: \(string)")
    }
}


extension DashboardRootViewController: WindowsManagerDelegate {

    func didDismissCoveringWindows() {
    }
}


extension DashboardRootViewController: NewContactVCDelegate {
    
    func shouldReloadContacts(reload: Bool) {
        if reload {
            loadContactsAndSyncMessages()
        }
    }
}


extension DashboardRootViewController: PaymentInvoiceDelegate {

    func willDismissPresentedView(paymentCreated: Bool) {
        rootViewController.setStatusBarColor(light: true)
        headerView.updateBalance()
    }
}



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
