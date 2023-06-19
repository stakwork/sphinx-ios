//
//  NewChatViewController+MessagesFetchExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatViewController {
    func fetchNewMessages() {
        DispatchQueue.global().async {
            self.chatListViewModel?.syncMessages(chatId: self.chat?.id, progressCallback: { _ in }) { (_, _) in }
        }
    }
}
