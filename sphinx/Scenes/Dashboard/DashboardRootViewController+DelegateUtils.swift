import UIKit



// MARK: - UITextFieldDelegate for handling search input
extension DashboardRootViewController: UITextFieldDelegate {
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        
        return true
    }
    
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        var currentString = (textField.text ?? "") as NSString
    
        currentString = currentString.replacingCharacters(
            in: range,
            with: string
        ) as NSString

        // TODO: This is probably a good place to feed the current search string into
        // the ViewModel for the currently displayed VC. Or perform
        // some update and feed the results of that to said ViewModel.
        
//        chatListObjectsArray = contactsService.getObjectsWith(
//            searchString: currentString
//        )
        
        return true
    }
}

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


extension DashboardRootViewController: CustomSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: CustomSegmentedControl,
        to index: Int
    ) {
        activeTab = DashboardTab(rawValue: index)!
        print("segmentedControl index changed to \(index)")
    }
}


extension DashboardRootViewController: ChatListHeaderDelegate {
    
    func leftMenuButtonTouched() {
        leftMenuDelegate?.shouldOpenLeftMenu()
    }
}
