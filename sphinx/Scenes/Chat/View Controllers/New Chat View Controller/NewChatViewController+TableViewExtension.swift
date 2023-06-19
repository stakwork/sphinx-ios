//
//  NewChatViewController+TableViewExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController {
    func configureTableView() {
        guard let chat = chat else {
            chatTableView.alpha = 1.0
            return
        }
        
        if let _ = chatTableDataSource {
            return
        }
        
        setTableViewHeight()
        shouldAdjustTableViewTopInset()
        
        chatTableDataSource = NewChatTableDataSource(
            chat: chat,
            tableView: chatTableView,
            headerImageView: getContactImageView(),
            bottomView: bottomView,
            delegate: self
        )
        
        chatViewModel.setDataSource(chatTableDataSource)
    }
    
    func getContactImageView() -> UIImageView? {
        let imageView = headerView.chatHeaderView.profileImageView
        
        if imageView?.isHidden == true {
            return nil
        }
        
        return imageView
    }
}

extension NewChatViewController : NewChatTableDataSourceDelegate, SocketManagerDelegate {
    func configureNewMessagesIndicatorWith(newMsgCount: Int) {
        DispatchQueue.main.async {
            self.newMsgsIndicatorView.configureWith(
                tableContentOffset: self.chatTableView.contentOffset.y,
                newMessagesCount: newMsgCount,
                andDelegate: self
            )
        }
    }
    
    func didScrollToBottom() {
        self.configureNewMessagesIndicatorWith(newMsgCount: 0)
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.chat?.setChatMessagesAsSeen()
        })
    }
    
    func didScrollOutOfBottomArea() {
        newMsgsIndicatorView.configureWith(
            tableContentOffset: self.chatTableView.contentOffset.y
        )
    }
    
    func shouldGoToAttachmentViewFor(
        messageId: Int,
        isPdf: Bool
    ) {
        if let attachmentFullScreenVC = AttachmentFullScreenViewController.instantiate(messageId: messageId, animated: isPdf) {
            self.navigationController?.present(attachmentFullScreenVC, animated: isPdf)
        }
    }
    
    func shouldGoToVideoPlayerFor(
        messageId: Int,
        with data: Data
    ) {
        let avVC = AVViewController.instantiate(data: data)
        self.present(avVC, animated: true, completion: nil)
    }
    
    func didTapOnContactWith(pubkey: String, and routeHint: String?) {
        if let contact = UserContact.getContactWith(pubkey: pubkey) {
            let chat = contact.getChat()
            goToChatWith(contactId: contact.id, chatId: chat?.id)
        } else {
            let routeHintString = (routeHint != nil && routeHint!.isNotEmpty) ? ":\(routeHint!)" : ""
            let newContactVC = NewContactViewController.instantiate(pubkey: "\(pubkey)\(routeHintString)")
            present(newContactVC, animated: true)
        }
    }
    
    func didTapOnTribeWith(joinLink: String) {
        if let uuid = GroupsManager.sharedInstance.getGroupInfo(query: joinLink)?.uuid, let chat = Chat.getChatWith(uuid: uuid) {
            goToChatWith(contactId: nil, chatId: chat.id)
        } else {
            let joinTribeVC = JoinGroupDetailsViewController.instantiate(qrString: joinLink)
            present(joinTribeVC, animated: true)
        }
    }
    
    func goToChatWith(
        contactId: Int?,
        chatId: Int?
    ) {
        let chatVC = NewChatViewController.instantiate(
            contactId: contactId,
            chatId: chatId,
            chatListViewModel: chatListViewModel
        )
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func didDeleteTribe() {
        navigationController?.popViewController(animated: true)
    }
    
    func didUpdateChat(_ chat: Chat) {
        self.chat = chat
    }
    
    func didUpdateChatFromMessage(_ chat: Chat) {
        if self.chat == nil {
            if let contact = self.contact, contact.id == chat.getContact()?.id {
                self.chat = chat
                
                configureFetchResultsController()
                configureTableView()
            }
        }
    }
    
    func didLongPressOnCellWith(messageId: Int, and rowIndex: Int, bubbleViewRect: CGRect) {
        let indexPath = IndexPath(row: rowIndex, section: 0)
        let cellOutOfBounds = chatTableView.isCellOutOfBounds(indexPath: indexPath)

        if cellOutOfBounds.0 || cellOutOfBounds.1 {
            chatTableView.scrollToRow(at: indexPath, at: cellOutOfBounds.0 ? .bottom : .top, animated: true)
        }

        DelayPerformedHelper.performAfterDelay(seconds: cellOutOfBounds.0 || cellOutOfBounds.1 ? 0.3 : 0.0, completion: {
            if self.isKeyboardVisible() {
                self.messageMenuData = MessageTableCellState.MessageMenuData(
                    messageId: messageId,
                    bubbleRect: bubbleViewRect,
                    indexPath: indexPath
                )
                self.view.endEditing(true)
            } else {
                self.showMessageMenuFor(
                    messageId: messageId,
                    indexPath: indexPath,
                    bubbleViewRect: bubbleViewRect
                )
            }
        })
    }
    
    func shouldShowLeaderboardFor(
        messageId: Int
    ) {
        guard let message = TransactionMessage.getMessageWith(id: messageId) else {
            return
        }
        
        if let matchedLeaderboardEntry = chatViewModel.getLeaderboardEntryFor(message: message) {
            let vc = MemberBadgeDetailVC.instantiate(delegate: self)

            let vm = MemberBadgeDetailVM(
                vc: vc,
                leaderBoardData: matchedLeaderboardEntry,
                message: message,
                knownTribeBadges: chatViewModel.availableBadges
            )

            vc.memberBadgeDetailVM = vm
            
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: false)
        } else {
            let tribeMemberPopupVC = TribeMemberPopupViewController.instantiate(message: message, delegate: self)
            tribeMemberPopupVC.modalPresentationStyle = .overCurrentContext
            self.present(tribeMemberPopupVC, animated: false)
        }
    }
}

extension NewChatViewController {
    func showMessageMenuFor(
        messageId: Int,
        indexPath: IndexPath,
        bubbleViewRect: CGRect
    ) {
        if let bubbleRectAndPath = MessageOptionsMenuHelper().getMessageBubbleRectAndPath(
            tableView: self.chatTableView,
            indexPath: indexPath,
            contentView: self.view,
            bubbleViewRect: bubbleViewRect
        ), let message = TransactionMessage.getMessageWith(id: messageId)
        {
            if message.getActionsMenuOptions().isEmpty {
                return
            }
            
            newMsgsIndicatorView.isHidden = true
            
            let messageOptionsVC = MessageOptionsViewController.instantiate(message: message, delegate: self)
            messageOptionsVC.setBubblePath(bubblePath: bubbleRectAndPath)
            messageOptionsVC.modalPresentationStyle = .overCurrentContext
            self.navigationController?.present(messageOptionsVC, animated: false)
        }
    }
}

extension NewChatViewController : NewMessagesIndicatorViewDelegate {
    func didTouchButton() {
        chatTableView.scrollToRow(index: 0, animated: true)
    }
}

extension NewChatViewController : TribeMemberViewDelegate {
    func shouldGoToSendPayment(message: TransactionMessage) {
        
        let viewController : UIViewController! = CreateInvoiceViewController.instantiate(
            contact: nil,
            chat: chat,
            messageUUID: message.uuid,
            delegate: self,
            paymentMode: PaymentsViewModel.PaymentMode.send
        )

        presentNavigationControllerWith(vc: viewController)
    }
    
    func shouldDisplayKnownBadges() {
        guard let chatId = chat?.id else {
            return
        }
        
        let badgeVC = BadgeMemberKnownBadgesVC.instantiate(
            chatID: chatId,
            badges: chatViewModel.availableBadges
        )
        
        self.navigationController?.pushViewController(badgeVC, animated: true)
    }
    
    func shouldDismissMemberPopup() {}
}
