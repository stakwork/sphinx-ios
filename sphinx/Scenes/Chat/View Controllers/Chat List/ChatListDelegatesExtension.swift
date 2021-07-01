//
//  ChatListDelegatesExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension ChatListViewController : ChatListDataSourceDelegate {
    func didTapChatRow(object: ChatListCommonObject) {
        API.sharedInstance.cleanMessagesRequest()
        
        if let contact = object as? UserContact, contact.isPending() {
            if let invite = contact.invite {
                if invite.isPendingPayment() {
                    payInvite(invite: invite)
                    return
                }
                
                let (ready, title, message) = invite.getInviteStatusForAlert()
                if ready {
                    goToInviteCodeString(inviteCode: contact.invite?.inviteString ?? "")
                } else {
                    AlertHelper.showAlert(title: title, message: message)
                }
            }
        } else {
            presentChatVC(object: object)
        }
    }
    
    func payInvite(invite: UserInvite) {
        AlertHelper.showTwoOptionsAlert(title: "pay.invitation".localized, message: "", confirm: {
            self.chatListViewModel.payInvite(invite: invite, completion: { contact in
                if let contact = contact {
                    self.didUpdateContact(contact: contact)
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "payment.failed".localized)
                }
            })
        })
    }
    
    func goToInviteCodeString(inviteCode: String) {
        if inviteCode == "" {
            return
        }
        let confirmAddfriendVC = ShareInviteCodeViewController.instantiate()
        confirmAddfriendVC.qrCodeString = inviteCode
        self.navigationController?.present(confirmAddfriendVC, animated: true, completion: nil)
    }
    
    func presentChatVC(object: ChatListCommonObject, animated: Bool = true, fromPush: Bool = false) {
        shouldReloadFriends = false
        
        var chatVC : ChatViewController!
        let chat = (object as? Chat) ?? ((object as? UserContact)?.getConversation())
        let contact = (object as? UserContact) ?? (object as? Chat)?.getContact()
        chatVC = ChatViewController.instantiate(contact: contact, chat: chat, preventFetching: !fromPush, contactsService: contactsService, rootViewController: rootViewController)
        navigationController?.pushViewController(chatVC, animated: animated)
        
        resetSearchField()
    }
    
    func didTapAddNewContact() {
        shouldReloadFriends = false

        let addfriendVC = AddFriendViewController.instantiate(rootViewController: rootViewController)
        addfriendVC.delegate = self
        let newNC = UINavigationController(rootViewController: addfriendVC)
        newNC.isNavigationBarHidden = true
        navigationController?.present(newNC, animated: true, completion: nil)
    }
    
    func didTapCreateGroup() {
        let createTribeVC = NewPublicGroupViewController.instantiate(rootViewController: rootViewController, delegate: self)
        let newNC = UINavigationController(rootViewController: createTribeVC)
        newNC.isNavigationBarHidden = true
        navigationController?.present(newNC, animated: true, completion: nil)
    }
}

extension ChatListViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        chatListObjectsArray = contactsService.getChatListObjects()
        loadDataSource()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString

        chatListObjectsArray = contactsService.getObjectsWith(searchString: currentString as String)
        loadDataSource()
        return true
    }
}

extension ChatListViewController : NewContactVCDelegate {
    func shouldReloadContacts(reload: Bool) {
        if reload {
            loadFriendAndReload()
        }
    }
}

extension ChatListViewController : QRCodeScannerDelegate {
    func shouldGoToChat() {
        goToChat()
    }
    
    func shouldPresentGroupDetailsWith(query: String) {
        let groupDetailsVC = JoinGroupDetailsViewController.instantiate(qrString: query, delegate: self)
        navigationController?.present(groupDetailsVC, animated: true, completion: nil)
    }
}

extension ChatListViewController : WindowsManagerDelegate {
    func didDismissCoveringWindows() {
        goToChat()
    }
}
