import UIKit



extension DashboardRootViewController: DashboardChatsListDelegate {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectChat chat: Chat
    ) {
//        API.sharedInstance.cleanMessagesRequest()
//
//        if let contact = object as? UserContact, contact.isPending() {
//            if let invite = contact.invite {
//                if invite.isPendingPayment() {
//                    payInvite(invite: invite)
//                    return
//                }
//
//                let (ready, title, message) = invite.getInviteStatusForAlert()
//                if ready {
//                    goToInviteCodeString(inviteCode: contact.invite?.inviteString ?? "")
//                } else {
//                    AlertHelper.showAlert(title: title, message: message)
//                }
//            }
//        } else {
//            presentChatVC(object: object)
//        }
    
        
        presentChatDetailsVC(chat: chat)
    }
    
    
    func viewControllerDidRefreshChats(
        _ viewController: UIViewController,
        using refreshControl: UIRefreshControl
    ) {
        loadContactsAndSyncMessages()
//        loadingRefresh = false
        
        refreshControl.endRefreshing()
    }
    

}
