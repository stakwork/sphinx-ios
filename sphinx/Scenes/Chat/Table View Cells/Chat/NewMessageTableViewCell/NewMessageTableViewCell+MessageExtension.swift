//
//  NewMessageTableViewCell+MessageExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    
    func configureWith(
        messageContent: BubbleMessageLayoutState.MessageContent?
    ) {
        if let messageContent = messageContent {
            messageLabel.text = messageContent.text
            messageLabel.font = messageContent.font
            
            textMessageView.isHidden = false
            bubbleOnlyText.isHidden = false
        }
    }
}
