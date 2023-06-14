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
    
    func shouldGoToVideoPlayerFor(messageId: Int) {
        
    }
}

extension NewChatViewController : NewMessagesIndicatorViewDelegate {
    func didTouchButton() {
        chatTableView.scrollToRow(index: 0, animated: true)
    }
}
