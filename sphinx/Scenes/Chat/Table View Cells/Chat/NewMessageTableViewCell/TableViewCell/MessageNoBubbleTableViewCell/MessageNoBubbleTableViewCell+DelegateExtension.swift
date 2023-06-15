//
//  MessageNoBubbleTableViewCell+DelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension MessageNoBubbleTableViewCell : GroupActionsViewDelegate {
    func didTapDeleteTribeButton() {
        if let messageId = messageId {
            delegate?.didTapDeleteTribeButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapApproveRequestButton() {
        if let messageId = messageId {
            delegate?.didTapApproveRequestButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapRejectRequestButton() {
        if let messageId = messageId {
            delegate?.didTapRejectRequestButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
