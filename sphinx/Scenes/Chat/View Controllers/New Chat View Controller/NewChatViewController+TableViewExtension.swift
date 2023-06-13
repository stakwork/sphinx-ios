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
            bottomView: bottomView
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
