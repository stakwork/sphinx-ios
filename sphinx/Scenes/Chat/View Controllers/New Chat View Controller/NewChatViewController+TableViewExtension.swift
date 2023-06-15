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
    }
    
    func getContactImageView() -> UIImageView? {
        let imageView = headerView.chatHeaderView.profileImageView
        
        if imageView?.isHidden == true {
            return nil
        }
        
        return imageView
    }
}

extension NewChatViewController : NewChatTableDataSourceDelegate {
    func configureNewMessagesIndicatorWith(newMsgCount: Int) {
        DispatchQueue.main.async {
            self.newMsgsIndicatorView.configureWith(
                firstVisibleRow: self.chatTableView.indexPathsForVisibleRows?.first?.row ?? 0,
                newMessagesCount: newMsgCount,
                andDelegate: self
            )
        }
    }
    
    func didScrollToBottom() {
        self.chat?.setChatMessagesAsSeen()
        self.configureNewMessagesIndicatorWith(newMsgCount: 0)
    }
    
    func didScrollOutOfBottomArea() {
        newMsgsIndicatorView.configureWith(
            firstVisibleRow: chatTableView.indexPathsForVisibleRows?.first?.row ?? 0
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
            chatId: chatId
        )
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func didDeleteTribe() {
        navigationController?.popViewController(animated: true)
    }
    
    func didUpdateChat(_ chat: Chat) {
        self.chat = chat
    }
}

extension NewChatViewController : NewMessagesIndicatorViewDelegate {
    func didTouchButton() {
        chatTableView.scrollToRow(index: 0, animated: true)
    }
}
