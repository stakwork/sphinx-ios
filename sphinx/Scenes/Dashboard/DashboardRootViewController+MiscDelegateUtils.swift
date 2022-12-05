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


extension DashboardRootViewController: ChatListHeaderDelegate {
    
    func leftMenuButtonTouched() {
        leftMenuDelegate?.shouldOpenLeftMenu()
    }
}
