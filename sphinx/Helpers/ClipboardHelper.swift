//
//  ClipboardHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class ClipboardHelper {
    
    public static func copyToClipboard(text: String, message: String? = "text.copied.clipboard".localized) {
        UIPasteboard.general.string = text
        SoundsPlayer.playHaptic()
        
        if let message = message {
            NewMessageBubbleHelper().showGenericMessageView(text: message)
        }
    }
}
