//
//  NewMessageTableViewCell+DelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewMessageTableViewCell : NewMessageReplyViewDelegate {
    func didTapMessageReplyView() {
        if let messageId = messageId {
            delegate?.didTapMessageReplyFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : JoinCallViewDelegate {
    func didTapCopyLink() {
        if let messageId = messageId {
            delegate?.didTapCallLinkCopyFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapAudioButton() {
        if let messageId = messageId {
            delegate?.didTapCallJoinAudioFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapVideoButton() {
        if let messageId = messageId {
            delegate?.didTapCallJoinVideoFor(messageId: messageId, and: rowIndex)
        }
    }
}
