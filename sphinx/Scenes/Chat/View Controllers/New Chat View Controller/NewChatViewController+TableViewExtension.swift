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
        
        chatTableDataSource = NewChatTableDataSource(
            chat: chat,
            tableView: chatTableView
        )
    }
}
