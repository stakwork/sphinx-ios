import UIKit



extension DashboardRootViewController: DashboardChatSelectionDelegate {
    
    func viewController(_ viewController: UIViewController, didSelectChat chat: Chat) {
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
}



extension DashboardRootViewController {
    
    func presentChatDetailsVC(
        chat: Chat,
        animated: Bool = true,
        fromPush: Bool = false
    ) {
//        shouldReloadFriends = false
        let contact = chat.getContact()
        
        let chatVC = ChatViewController.instantiate(
            contact: contact,
            chat: chat,
            preventFetching: !fromPush,
            contactsService: contactsService,
            rootViewController: rootViewController
        )
        
        navigationController?.pushViewController(chatVC, animated: animated)
        
        resetSearchField()
    }
}
