//
//  NewOnlyTextMessageTableViewCell+DelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewOnlyTextMessageTableViewCell : ChatAvatarViewDelegate {
    func didTapAvatarView() {
        if let messageId = messageId {
            delegate?.didTapAvatarViewFor(messageId: messageId, and: rowIndex)
        }
    }
}
