import UIKit


extension DashboardRootViewController: QRCodeScannerDelegate {
    func didScanDeepLink() {
        handleLinkQueries()
    }
    
    
    func didScanQRCode(string: String) {
        print("QR Code Scanned: \(string)")
    }
}


extension DashboardRootViewController: WindowsManagerDelegate {

    func didDismissCoveringWindows() {}
}


extension DashboardRootViewController: NewContactVCDelegate {
    
    func shouldReloadContacts(reload: Bool, dashboardTabIndex: Int) {
        if reload {
            loadContactsAndSyncMessages()
        }
        
        if dashboardTabIndex >= 0 || dashboardTabIndex <= 2 {
            dashboardNavigationTabs.selectTabWith(index: dashboardTabIndex)
        }
    }
}


extension DashboardRootViewController: PaymentInvoiceDelegate {

    func willDismissPresentedView(paymentCreated: Bool) {
        setStatusBarColor()
        headerView.updateBalance()
    }
}


extension DashboardRootViewController: ChatListHeaderDelegate {
    
    func leftMenuButtonTouched() {
        leftMenuDelegate?.shouldOpenLeftMenu()
    }
}
