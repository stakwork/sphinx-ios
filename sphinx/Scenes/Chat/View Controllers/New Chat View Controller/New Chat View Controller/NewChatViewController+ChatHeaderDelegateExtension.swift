//
//  NewChatViewController+ChatHeaderDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController : ChatHeaderViewDelegate {
    func didTapHeaderButton() {
        var vc: UIViewController? = nil
        
        if let contact = contact {
            vc = NewContactViewController.instantiate(contactId: contact.id)
        } else if let chat = chat, chat.isGroup() {
            vc = GroupDetailsViewController.instantiate(chat: chat)
        }
        
        if let vc = vc {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didTapBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func didTapWebAppButton() {
        toggleWebAppContainer()
    }
    
    func didTapMuteButton() {
        guard let chat = chat else {
            return
        }
        
        if chat.isPublicGroup() {
            goToNotificationsLevel()
        } else {
            chatViewModel.toggleVolume(
                completion: { chat in
                    if let chat = chat, chat.isMuted(){
                        self.messageBubbleHelper.showGenericMessageView(
                            text: "chat.muted.message".localized,
                            delay: 2.5
                        )
                    }
                }
            )
        }
    }
    
    func didTapMoreOptionsButton(sender: UIButton) {
        let alert = CustomAlertController(
            title: "chat.options".localized,
            message: "select.option".localized,
            preferredStyle: .actionSheet
        )

        let isPublicGroup = chat?.isPublicGroup() ?? false
        let isMyPublicGroup = chat?.isMyPublicGroup() ?? false
        
        alert.addAction(
            UIAlertAction(
                title: "create.call".localized,
                style: .default,
                handler: { (UIAlertAction) in
                    self.chatViewModel.createCallMessage(sender: sender)
                }
            )
        )

        if isPublicGroup {
            alert.addAction(
                UIAlertAction(
                    title: "notifications.level".localized,
                    style: .default,
                    handler: { (UIAlertAction) in
                        self.goToNotificationsLevel()
                    }
                )
            )
            
            if isMyPublicGroup {
                alert.addAction(
                    UIAlertAction(
                        title: "share.group".localized,
                        style: .default,
                        handler: { (UIAlertAction) in
                            self.goToShare()
                        }
                    )
                )
            }
        }

        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel ))
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds

        self.present(alert, animated: true, completion: nil)
    }
    
    func goToShare() {
        if let link = chat?.getJoinChatLink() {
            
            let qrCodeDetailViewModel = QRCodeDetailViewModel(
                qrCodeString: link,
                amount: 0,
                viewTitle: "share.group.link".localized
            )
            
            let viewController = QRCodeDetailViewController.instantiate(
                with: qrCodeDetailViewModel,
                presentedVCDelegate: nil
            )
            
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    func goToNotificationsLevel() {
        if let chat =  chat {
            
            let notificationsVC = NotificationsLevelViewController.instantiate(
                chatId: chat.id
            )
            
            self.present(notificationsVC, animated: true)
        }
    }
}

extension NewChatViewController : ChatSearchTextFieldViewDelegate {
    func shouldSearchFor(term: String) {
        
    }
    
    func didTapSearchCancelButton() {
        
    }
}

extension NewChatViewController : ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton) {
        
    }
}
