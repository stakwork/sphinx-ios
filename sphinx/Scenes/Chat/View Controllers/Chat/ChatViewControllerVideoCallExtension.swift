//
//  ChatViewControllerVideoCallExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import JitsiMeetSDK

extension ChatViewController {
    func configureVideoCallManager() {
        VideoCallManager.sharedInstance.configure(chat: chat, videoCallDelegate: self)
    }
    
    func configureAudioSession() -> Bool {
        let didAskForPermissions = audioHelper.configureAudioSession(delegate: self)
        return didAskForPermissions
    }
    
    func startVideoCall(link: String, audioOnly: Bool) {
        accessoryView.shouldDismissKeyboard()
        accessoryView.hide()
        
        VideoCallManager.sharedInstance.startVideoCall(link: link, audioOnly: audioOnly)
    }
    
    func didFinishCall() {
        accessoryView.show()
    }
}

extension ChatViewController : VideoCallDelegate {
    func didSwitchMode(pip: Bool) {
        accessoryView.shouldDismissKeyboard()
        
        if (pip) {
            accessoryView.show()
        } else {
            accessoryView.hide()
        }
    }
    
    func didTapButton(callback: @escaping () -> ()) {
        shouldSendPayment(amount: UserContact.kTipAmount, callback: { success in
            if success {
                VideoCallManager.sharedInstance.paymentSent()
            } else {
                NewMessageBubbleHelper().showGenericMessageView(text: "payment.failed.upper".localized)
            }
            callback()
        })
    }
    
    func shouldSendPayment(amount: Int, callback: @escaping (Bool) -> ()) {
        chatViewModel.resetCurrentPayment()
        chatViewModel.currentPayment.amount = amount
        
        chatViewModel.shouldSendDirectPayment(parameters: chatViewModel.getParams(contacts: chat?.getContacts(includeOwner: false), chat: chat), callback: { message in
            if let message = message {
                self.didCreateMessage(message: message)
                callback(true)
            } else {
                callback(false)
            }
        }, errorCallback: {
            callback(false)
        })
    }
}
