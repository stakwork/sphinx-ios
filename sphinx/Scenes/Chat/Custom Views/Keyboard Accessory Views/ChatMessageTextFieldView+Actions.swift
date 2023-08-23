//
//  ChatMessageTextFieldView+Actions.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ChatMessageTextFieldView {
    @IBAction func attachmentButtonTouched() {
        self.endEditing(true)
        
        delegate?.didTapAttachmentsButton?(text: self.textView.text)
    }
    
    @IBAction func sendButtonTouched() {
        sendButton.isUserInteractionEnabled = false

        let currentString = (textView.text ?? "").trim()

        if currentString == "" || currentString == placeHolderText {
            if let didTapSendButton = delegate?.didTapSendBlueButton {
                didTapSendButton()
            } else {
                sendButton.isUserInteractionEnabled = true
            }
            return
        }

        createNewMessage(text: currentString as String)
    }
    
    @IBAction func audioButtonTouchedDown() {
        toggleAudioRecording(show: true)
        delegate?.shouldStartRecording?()
    }
    
    @IBAction func audioButtonTouchUpInside() {
        toggleAudioRecording(show: false)
        delegate?.shouldStopAndSendAudio?()
    }
    
    @IBAction func audioButtonDragOutside() {
        NewMessageBubbleHelper().showGenericMessageView(text: "audio.message.cancelled".localized)
        toggleAudioRecording(show: false)
        delegate?.shouldCancelRecording?()
    }
}
