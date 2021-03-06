//
//  Library
//
//  Created by Tomas Timinskas on 08/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import Starscream
import SwiftyJSON
import GiphyUISDK

extension ChatViewController {
    func askForNotificationPermissions() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.registerForPushNotifications()
    }
    
    func showAlert(title: String, message: String) {
        AlertHelper.showAlert(title: title, message: message)
    }
    
    func addObservers() {
        accessoryView.addKeyboardObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(onMessageLongPressed(_:)), name: .onMessageLongPressed, object: nil)
        
        NotificationCenter.default.addObserver(forName: .onMessageMenuShow, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.accessoryView.hide()
            self.headerView.alpha = 0.0
        }
        
        NotificationCenter.default.addObserver(forName: .onMessageMenuHide, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.accessoryView.show(animated: false)
            self.headerView.alpha = 1.0
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .onMessageLongPressed, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onMessageMenuShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onMessageMenuHide, object: nil)
    }
    
    @objc func onMessageLongPressed(_ notification:Notification) {
        WindowsManager.sharedInstance.showMessageOptions(notification, delegate: self)
    }
}

extension ChatViewController : ChatHeaderViewDelegate {
    func didTapHeaderButton() {
        accessoryView.shouldDismissKeyboard()

        if let contact = contact {
            let newContactVC = NewContactViewController.instantiate(rootViewController: rootViewController, contact: contact)
            newContactVC.delegate = self
            self.navigationController?.pushViewController(newContactVC, animated: true)
        } else if let chat = chat, chat.isGroup() {
            let groupDetailsVC = GroupDetailsViewController.instantiate(rootViewController: rootViewController, chat: chat, delegate: self)
            self.navigationController?.pushViewController(groupDetailsVC, animated: true)
        }
    }
    
    func didTapBackButton() {
        UserDefaults.Keys.chatId.removeValue()
        chat?.setChatMessagesAsSeen()
        accessoryView.shouldDismissKeyboard()
        accessoryView.hide()
        webAppVC?.stopWebView()
        navigationController?.popViewController(animated: true)
    }
    
    func didTapWebAppButton() {
        toggleWebAppContainer()
    }
    
    func didTapMuteButton() {
        guard let chat = chat else {
            return
        }
        chatViewModel.toggleVolumeOn(chat: chat, completion: { chat in
            if let chat = chat {
                if chat.isMuted() {
                    self.messageBubbleHelper.showGenericMessageView(text: "chat.muted.message".localized, delay: 2.5)
                }
                self.updateViewChat(updatedChat: chat)
            }
            self.chatHeaderView.setVolumeState()
        })
    }
    
    func didTapCallButton(sender: UIButton) {
        VideoCallHelper.createCallMessage(button: sender, callback: { link in
            let messageType = TransactionMessage.TransactionMessageType.message.rawValue
            self.shouldSendMessage(text: link, type: messageType, completion: { _ in })
        })
    }
}

extension ChatViewController : ChatAccessoryViewDelegate {
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ()) {
        var messageText = text
        
        if let podcastComment = accessoryView.getReplyingPodcast() {
            messageText = podcastComment.getJsonString(withComment: text) ?? text
        }
        
        let (botAmount, wrongAmount) = isWrongBotCommandAmount(text: messageText)
        if wrongAmount {
            return
        }
        
        let _ = createProvisionalAndSend(messageText: messageText, type: type, botAmount: botAmount, completion: completion)
    }
    
    func createProvisionalAndSend(messageText: String, type: Int, botAmount: Int, completion: @escaping (Bool) -> ()) -> TransactionMessage? {
        let provisionalMessage = insertPrivisionalMessage(text: messageText, type: type, chat: chat)
        sendMessage(provisionalMessage: provisionalMessage, text: messageText, botAmount: botAmount, completion: completion)
        return provisionalMessage
    }
    
    func isWrongBotCommandAmount(text: String) -> (Int, Bool) {
        let (botAmount, failureMessage) = GroupsManager.sharedInstance.calculateBotPrice(chat: chat, text: text)
        if let failureMessage = failureMessage {
            accessoryView.setTextBack(text: text)
            showAlert(title: "generic.error.title".localized, message: failureMessage)
            return (botAmount, true)
        }
        return (botAmount, false)
    }
    
    func sendMessage(provisionalMessage: TransactionMessage?, text: String, botAmount: Int = 0, completion: @escaping (Bool) -> ()) {
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: provisionalMessage?.type ?? 0)
        guard let params = TransactionMessage.getMessageParams(contact: contact, chat: chat, type: messageType, text: text, botAmount: botAmount, replyingMessage: accessoryView.getReplyingMessage()) else {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.didFailSendingMessage(provisionalMessage: provisionalMessage)
            })
            return
        }
        sendMessage(provisionalMessage: provisionalMessage, params: params, completion: completion)
    }
    
    func sendMessage(provisionalMessage: TransactionMessage?, params: [String: AnyObject], completion: @escaping (Bool) -> ()) {
        askForNotificationPermissions()
        accessoryView.hideReplyView()
        
        API.sharedInstance.sendMessage(params: params, callback: { m in
            if let message = TransactionMessage.insertMessage(m: m, existingMessage: provisionalMessage).0 {
                message.setPaymentInvoiceAsPaid()
                self.insertSentMessage(message: message, completion: completion)
            }
        }, errorCallback: {
             if let provisionalMessage = provisionalMessage {
                provisionalMessage.status = TransactionMessage.TransactionMessageStatus.failed.rawValue
                provisionalMessage.saveMessage()
                self.insertSentMessage(message: provisionalMessage, completion: completion)
                self.scrollAfterInsert()
             }
        })
    }
    
    func insertPrivisionalMessage(text: String, type: Int, chat: Chat?) -> TransactionMessage? {
        let message = TransactionMessage.createProvisionalMessage(messageContent: text, type: type, date: Date(), chat: chat, replyUUID: accessoryView.getReplyingMessage()?.uuid)
        
        if let message = message {
            chatDataSource?.addMessageAndReload(message: message, provisional: true)
        }
        return message
    }
    
    func insertSentMessage(message: TransactionMessage, completion: @escaping (Bool) -> ()) {
        updateViewChat(updatedChat: chat ?? contact?.getConversation())
        enableViewAndComplete(success: true, completion: completion)
        chatDataSource?.addMessageAndReload(message: message)
    }
    
    func enableViewAndComplete(success: Bool, completion: @escaping (Bool) -> ()) {
        view.isUserInteractionEnabled = true
        chat?.resetOngoingMessage()
        completion(success)
    }
    
    func errorProcessing(completion: @escaping (Bool) -> ()) {
        loading = false
        showErrorAlert()
        completion(false)
    }
    
    func showErrorAlert() {
        showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    func didChangeAccessoryViewHeight(heightDiff: CGFloat, updatedText: String) {
        chat?.setOngoingMessage(text: accessoryView.getMessage())
        addBottomInset(height: heightDiff)
    }
    
    func getContacts() -> [UserContact] {
        return contact != nil ? [contact!] : []
    }
    
    func didTapAttachmentsButton() {
        if AttachmentsManager.sharedInstance.uploading || self.presentedViewController != nil {
            return
        }
        
        accessoryView.hide()
        
        let viewController = ChatAttachmentViewController.instantiate(delegate: self, chat: chat, text: accessoryView.getMessage(), replyingMessage: accessoryView.getReplyingMessage())
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: false)
    }
    
    func shouldShowAlert(title: String, message: String) {
        showAlert(title: title, message: message)
    }
    
    func shouldStartRecording() {
        let didAskForPermissions = configureAudioSession()
        if !didAskForPermissions {
            audioHelper.shouldStartRecording()
        }
    }
    
    func shouldStopAndSendAudio() {
        audioHelper.shouldFinishRecording()
    }
    
    func shouldCancelRecording() {
        audioHelper.shouldCancelRecording()
    }
}

extension ChatViewController : ChatDataSourceDelegate {
    func didScrollToBottom() {
        unseenMessagesCount = 0
        scrollDownLabel.text = "+1"
        scrollDownContainer.isHidden = true
    }
    
    func didDeleteGroup() {
        NotificationCenter.default.post(name: .onGroupDeleted, object: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func chatUpdated(chat: Chat) {
        messageBubbleHelper.hideLoadingWheel()
        updateViewChat(updatedChat: chat)
    }
}

extension ChatViewController : MessageCellDelegate {
    func didTapPayButton(message: TransactionMessage, cell: InvoiceReceivedTableViewCell) {
        accessoryView.shouldDismissKeyboard()
        
        processingPR = message
        processingPRCell = cell

        guard let _ = processingPR?.invoice else {
            return
        }
        
        self.accessoryView.hide()
        let viewController = PayInvoiceViewController.instantiate(message: message, delegate: self)
        self.present(viewController, animated: false)
    }
    
    func didTapAttachmentRow(message: TransactionMessage) {
        accessoryView.shouldDismissKeyboard()
        WindowsManager.sharedInstance.showFullScreenImage(message: message)
    }
    
    func didTapAttachmentCancel(message: TransactionMessage) {
        AttachmentsManager.sharedInstance.cancelUpload()
        chatDataSource?.deleteCellFor(m: message)
        CoreDataManager.sharedManager.deleteObject(object: message)
    }
    
    func shouldPlayVideo(url: URL?, data: Data?) {
        if let data = data {
            accessoryView.shouldDismissKeyboard()
            accessoryView.hide()
            preventLoading = true
            
            let avVC = AVViewController.instantiate(data: data, delegate: self)
            self.present(avVC, animated: true, completion: nil)
        }
    }
    
    func shouldStartCall(link: String, audioOnly: Bool) {
        startVideoCall(link: link, audioOnly: audioOnly)
    }
    
    func shouldReplayToMessage(message: TransactionMessage) {
        configureReplayToMessage(message: message)
    }
    
    func shouldGoBackToDashboard() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func didTapPayAttachment(message: TransactionMessage) {
        let attachmentsManager = AttachmentsManager.sharedInstance
        attachmentsManager.payAttachment(message: message, chat: chat, callback: { purchaseMessage in
            if let purchaseMessage = purchaseMessage {
                let _ = self.chatDataSource?.reloadAttachmentRow(m: purchaseMessage)
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        })
    }
    
    func shouldReloadCell(cell: UITableViewCell) {
        if let indexPath = chatTableView.indexPath(for: cell) {
            chatTableView.reloadRows(at: [indexPath], with: .none)
            
            if chatTableView.shouldScrollToBottom() {
                scrollChatToBottom()
            }
        }
    }
    
    func shouldScrollTo(message: TransactionMessage) {
        chatDataSource?.scrollTo(message: message)
    }
    
    func shouldScrollToBottom() {
        if chatTableView.shouldScrollToBottom() {
            scrollChatToBottom()
        }
    }
    
    func didTapOnPubKey(pubkey: String) {
        if pubkey == UserData.sharedInstance.getUserPubKey() { return }
        let (pk, _) = pubkey.pubkeyComponents
        let (existing, user) = pk.isExistingContactPubkey()
        if let user = user, existing {
            if let chat = user.getConversation() {
                UserDefaults.Keys.chatId.set(chat.id)
            } else {
                UserDefaults.Keys.contactId.set(user.id)
            }
            navigationController?.popViewController(animated: true)
        } else {
            accessoryView.hide()
            
            let newContactVC = NewContactViewController.instantiate(rootViewController: rootViewController, pubkey: pubkey)
            newContactVC.delegate = self
            present(newContactVC, animated: true, completion: nil)
        }
    }
    
    func fileDownloadButtonTouched(message: TransactionMessage, data: Data, button: UIButton) {
        if let fileURL = MediaLoader.saveFileInMemory(data: data, name: message.getFileName()){
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = button
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}

extension ChatViewController : PaymentInvoiceDelegate, GroupPaymentVCDelegate {    
    func didCreateMessage(message: TransactionMessage) {
        accessoryView.show()
        chatDataSource?.addMessageAndReload(message: message)
        view.isUserInteractionEnabled = true
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.scrollChatToBottom()
        }
    }
    
    func didFailCreatingInvoice() {
        errorProcessing(completion: {_ in })
    }
    
    func willDismissPresentedView(paymentCreated: Bool) {
        if paymentCreated {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
                self.accessoryView.show()
                self.addPaymentForInvoice()
            }
        } else {
            accessoryView.show()
        }
    }
    
    func shouldSendOnchain(address: String, amount: Int) {
        let loopoutCommandMsg = "/loopout \(address) \(amount)"
        let messageType = TransactionMessage.TransactionMessageType.message.rawValue
        shouldSendMessage(text: loopoutCommandMsg, type: messageType, completion: { _ in })
    }
    
    func addPaymentForInvoice() {
        if let _ = processingPR {
            animateInvoiceCell()
            loading = false
        }
    }
    
    func animateInvoiceCell() {
        if let cell = processingPRCell {
            cell.animatePayingAction(completion: {
                self.reloadAfterPay()
            })
        } else {
            reloadAfterPay()
        }
    }
    
    func reloadAfterPay() {
        view.isUserInteractionEnabled = false
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.reloadMessages(newMessageCount: 1)
        }
    }
}

extension ChatViewController : SocketManagerDelegate {
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        if let indexPath = chatDataSource?.reloadAttachmentRow(m: message) {
            DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                self.chatTableView.shouldScrollToUpdatedRowAt(indexPath: indexPath)
            })
        }
    }
    
    func didReceiveMessage(message: TransactionMessage, shouldSync: Bool) {
        if WindowsManager.sharedInstance.isOnMessageOptionsMenu() {
            return
        }
        
        if self.chat == nil {
            updateViewChat(updatedChat: message.chat)
        }
        
        if message.isPayment() {
            if shouldSync {
                fetchNewData()
            } else {
                reloadMessages(newMessageCount: 1)
            }
            return
        }
        
        chatDataSource?.addMessageAndReload(message: message)
        scrollAfterInsert()
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
        if WindowsManager.sharedInstance.isOnMessageOptionsMenu() {
            return
        }
        
        chatDataSource?.addMessageAndReload(message: message, confirmation: true)
        scrollAfterInsert()
    }
    
    func didUpdateContact(contact: UserContact) {
        self.contact = contact
        updateViewChat(updatedChat: contact.getConversation())
        chatDataSource?.updateContact(contact: contact)
        chatHeaderView.setChatInfo()
    }
    
    func didUpdateChat(chat: Chat) {
        updateViewChat(updatedChat: chat)
        accessoryView.updateFromChat(chat)
    }
    
    func scrollAfterInsert(count: Int = 1) {
        if chatTableView.shouldScrollToBottom() {
            scrollChatToBottom()
        } else {
            unseenMessagesCount = unseenMessagesCount + count
            scrollDownLabel.text = "+\(unseenMessagesCount)"
            scrollDownContainer.isHidden = false
        }
    }
}

extension ChatViewController : NewContactVCDelegate {
    func shouldReloadContacts(reload: Bool) {
        contact = UserContact.getContactWith(id: contact?.id ?? -1)
        updateViewChat(updatedChat: chat ?? contact?.getConversation())
        loadData()
    }
}

extension ChatViewController : PresentedViewDelegate {
    func didDismissPresentedView() {
        accessoryView.show()
    }
}

extension ChatViewController : AudioHelperDelegate {
    func didStartRecording(_ success: Bool) {
        if success {
            inputAccessoryView.didStartRecording()
        } else {
            NewMessageBubbleHelper().showGenericMessageView(text: "microphone.permission.denied".localized, delay: 5)
        }
    }
    
    func didFinishRecording(_ success: Bool) {
        if success {
            if let audio = audioHelper.getAudioData() {
                let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: audio)
                if let encryptedData = encryptedData {
                    let attachmentObject = AttachmentObject(data: encryptedData, mediaKey: key, type: AttachmentsManager.AttachmentType.Audio)
                    shouldStartUploading(attachmentObject: attachmentObject)
                }
            }
        }
    }
    
    func audioTooShort() {
        let windowInset = getWindowInsets()
        let y = WindowsManager.getWindowHeight() - windowInset.bottom - inputAccessoryView.frame.size.height
        NewMessageBubbleHelper().showAudioTooltip(y: y)
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        inputAccessoryView.updateRecordingAudio(minutes: minutes, seconds: seconds)
    }
}

extension ChatViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
            navigationController?.popViewController(animated: true)
        }
        return false
    }
}

extension ChatViewController : MessageOptionsVCDelegate {
    func shouldRemoveWindow() {
        WindowsManager.sharedInstance.removeMessageOptions()
        fetchNewData()
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        configureReplayToMessage(message: message)
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        guard let params = TransactionMessage.getBoostMessageParams(contact: contact, chat: chat, replyingMessage: message) else {
            return
        }
        sendMessage(provisionalMessage: nil, params: params, completion: {_ in })
    }
    
    func shouldDeleteMessage(message: TransactionMessage) {
        if message.id < 0 {
            chatDataSource?.deleteCellFor(m: message)
            CoreDataManager.sharedManager.deleteObject(object: message)
            return
        }
        
        self.view.isUserInteractionEnabled = false
        
        API.sharedInstance.deleteMessage(messageId: message.id, callback: { (success, m) in
            self.view.isUserInteractionEnabled = true
            let updatedMessage = TransactionMessage.insertMessage(m: m).0
            
            if success {
                self.updateDeletedMessageRow(message: updatedMessage ?? message)
                return
            }
            
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        })
    }
    
    func updateDeletedMessageRow(message: TransactionMessage) {
        chatDataSource?.updateDeletedMessage(m: message)
        PlayAudioHelper.playHaptic()
    }
}

extension ChatViewController : GroupDetailsDelegate {
    func shouldReloadMessage(message: TransactionMessage) {
        chatDataSource?.addMessageAndReload(message: message)
    }
}

