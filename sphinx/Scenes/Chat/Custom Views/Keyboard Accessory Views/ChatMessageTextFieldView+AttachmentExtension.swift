//
//  ChatMessageTextFieldView+AttachmentExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ChatMessageTextFieldView {
    func setupForAttachments(with text: String? = nil) {
        mode = MessagesFieldMode.Attachment
        
        if let text = text, !text.isEmpty && text != kFieldPlaceHolder {
            textView.text = text
            textView.textColor = UIColor.Sphinx.TextMessages
        } else {
            textView.text = kAttchmentFieldPlaceHolder
        }

        animateElements(sendButtonVisible: true)
        textViewDidChange(textView)
    }
}
