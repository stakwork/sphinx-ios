//
//  Library
//
//  Created by Tomas Timinskas on 01/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ChatHelper {
    
    public static func getSenderColorFor(message: TransactionMessage) -> UIColor {
        var key:String? = nil
        
        if !(message.chat?.isPublicGroup() ?? false) || message.senderId == 1 {
            key = "\(message.senderId)-color"
        }
        
        if let senderAlias = message.senderAlias, !senderAlias.isEmpty {
            key = "\(senderAlias.trim())-color"
        }

        if let key = key {
            return UIColor.getColorFor(key: key)
        }
        return UIColor.Sphinx.SecondaryText
    }
    
    public static func getRecipientColorFor(
        message: TransactionMessage
    ) -> UIColor {
        if let recipientAlias = message.recipientAlias, !recipientAlias.isEmpty {
            return UIColor.getColorFor(
                key: "\(recipientAlias.trim())-color"
            )
        }
        
        return UIColor.Sphinx.SecondaryText
    }
    
    public static func registerCellsForChat(tableView: UITableView) {
        tableView.registerCell(MessageSentTableViewCell.self)
        tableView.registerCell(MessageReceivedTableViewCell.self)
        tableView.registerCell(PaymentReceivedTableViewCell.self)
        tableView.registerCell(PaymentSentTableViewCell.self)
        tableView.registerCell(InvoiceSentTableViewCell.self)
        tableView.registerCell(InvoiceReceivedTableViewCell.self)
        tableView.registerCell(ExpiredInvoiceSentTableViewCell.self)
        tableView.registerCell(ExpiredInvoiceReceivedTableViewCell.self)
        tableView.registerCell(PaidInvoiceSentTableViewCell.self)
        tableView.registerCell(PaidInvoiceReceivedTableViewCell.self)
        tableView.registerCell(DayHeaderTableViewCell.self)
        tableView.registerCell(DirectPaymentSentTableViewCell.self)
        tableView.registerCell(DirectPaymentReceivedTableViewCell.self)
        tableView.registerCell(PictureSentTableViewCell.self)
        tableView.registerCell(PictureReceivedTableViewCell.self)
        tableView.registerCell(VideoSentTableViewCell.self)
        tableView.registerCell(VideoReceivedTableViewCell.self)
        tableView.registerCell(AudioSentTableViewCell.self)
        tableView.registerCell(AudioReceivedTableViewCell.self)
        tableView.registerCell(GroupActionMessageTableViewCell.self)
        tableView.registerCell(GroupRemovedTableViewCell.self)
        tableView.registerCell(GroupRequestTableViewCell.self)
        tableView.registerCell(LoadingMoreTableViewCell.self)
        tableView.registerCell(VideoCallSentTableViewCell.self)
        tableView.registerCell(VideoCallReceivedTableViewCell.self)
        tableView.registerCell(PaidMessageSentTableViewCell.self)
        tableView.registerCell(PaidMessageReceivedTableViewCell.self)
        tableView.registerCell(DeletedMessageSentTableViewCell.self)
        tableView.registerCell(DeletedMessageReceivedTableViewCell.self)
        tableView.registerCell(MessageWebViewTableViewCell.self)
        tableView.registerCell(FileSentTableViewCell.self)
        tableView.registerCell(FileReceivedTableViewCell.self)
        tableView.registerCell(PodcastCommentReceivedTableViewCell.self)
        tableView.registerCell(PodcastCommentSentTableViewCell.self)
        tableView.registerCell(PodcastBoostReceivedTableViewCell.self)
        tableView.registerCell(PodcastBoostSentTableViewCell.self)
    }
    
    func getCellFor(messageRow: TransactionMessageRow, indexPath: IndexPath, on tableView: UITableView) -> UITableViewCell {
        let isVideoCallLink = messageRow.isVideoCallLink
        let isGiphy = messageRow.isGiphy
        let isPodcastComment = messageRow.isPodcastComment
        let isPodcastBoost = messageRow.isPodcastBoost
        
        var cell = UITableViewCell()
        
        guard let type = messageRow.getType() else {
            if let _ = messageRow.headerDate {
                cell = tableView.dequeueReusableCell(withIdentifier: "DayHeaderTableViewCell", for: indexPath) as! DayHeaderTableViewCell
                return cell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "LoadingMoreTableViewCell", for: indexPath) as! LoadingMoreTableViewCell
                return cell
            }
        }
        
        guard let message = messageRow.transactionMessage else {
            return cell
        }
        
        let incoming = messageRow.isIncoming()
        
        if message.isDeleted() || message.isFlagged() {
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeletedMessageReceivedTableViewCell", for: indexPath) as! DeletedMessageReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeletedMessageSentTableViewCell", for: indexPath) as! DeletedMessageSentTableViewCell
            }
            return cell
        }
        
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: Int(type))
        switch (messageType) {
        case TransactionMessage.TransactionMessageType.message:
            if incoming {
                if isVideoCallLink {
                    cell = tableView.dequeueReusableCell(withIdentifier: "VideoCallReceivedTableViewCell", for: indexPath) as! VideoCallReceivedTableViewCell
                } else if isGiphy {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PictureReceivedTableViewCell", for: indexPath) as! PictureReceivedTableViewCell
                } else if isPodcastComment {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PodcastCommentReceivedTableViewCell", for: indexPath) as! PodcastCommentReceivedTableViewCell
                } else if isPodcastBoost {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PodcastBoostReceivedTableViewCell", for: indexPath) as! PodcastBoostReceivedTableViewCell
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "MessageReceivedTableViewCell", for: indexPath) as! MessageReceivedTableViewCell
                }
            } else {
                if isVideoCallLink {
                     cell = tableView.dequeueReusableCell(withIdentifier: "VideoCallSentTableViewCell", for: indexPath) as! VideoCallSentTableViewCell
                } else if isGiphy {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PictureSentTableViewCell", for: indexPath) as! PictureSentTableViewCell
                } else if isPodcastComment {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PodcastCommentSentTableViewCell", for: indexPath) as! PodcastCommentSentTableViewCell
                } else if isPodcastBoost {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PodcastBoostSentTableViewCell", for: indexPath) as! PodcastBoostSentTableViewCell
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "MessageSentTableViewCell", for: indexPath) as! MessageSentTableViewCell
                }
            }
        case TransactionMessage.TransactionMessageType.boost:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "PodcastBoostReceivedTableViewCell", for: indexPath) as! PodcastBoostReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "PodcastBoostSentTableViewCell", for: indexPath) as! PodcastBoostSentTableViewCell
            }
        case TransactionMessage.TransactionMessageType.invoice:
            if incoming {
                if message.isPaid() {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PaidInvoiceReceivedTableViewCell", for: indexPath) as! PaidInvoiceReceivedTableViewCell
                } else if message.isExpired() {
                    cell = tableView.dequeueReusableCell(withIdentifier: "ExpiredInvoiceReceivedTableViewCell", for: indexPath) as! ExpiredInvoiceReceivedTableViewCell
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "InvoiceReceivedTableViewCell", for: indexPath) as! InvoiceReceivedTableViewCell
                }
            } else {
                if message.isPaid() {
                    cell = tableView.dequeueReusableCell(withIdentifier: "PaidInvoiceSentTableViewCell", for: indexPath) as! PaidInvoiceSentTableViewCell
                } else if message.isExpired() {
                    cell = tableView.dequeueReusableCell(withIdentifier: "ExpiredInvoiceSentTableViewCell", for: indexPath) as! ExpiredInvoiceSentTableViewCell
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "InvoiceSentTableViewCell", for: indexPath) as! InvoiceSentTableViewCell
                }
            }
        case TransactionMessage.TransactionMessageType.payment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "PaymentReceivedTableViewCell", for: indexPath) as! PaymentReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "PaymentSentTableViewCell", for: indexPath) as! PaymentSentTableViewCell
            }
        case TransactionMessage.TransactionMessageType.confirmation:
            break
        case TransactionMessage.TransactionMessageType.cancellation:
            break
        case TransactionMessage.TransactionMessageType.directPayment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "DirectPaymentReceivedTableViewCell", for: indexPath) as! DirectPaymentReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "DirectPaymentSentTableViewCell", for: indexPath) as! DirectPaymentSentTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.imageAttachment, TransactionMessage.TransactionMessageType.pdfAttachment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "PictureReceivedTableViewCell", for: indexPath) as! PictureReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "PictureSentTableViewCell", for: indexPath) as! PictureSentTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.videoAttachment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "VideoReceivedTableViewCell", for: indexPath) as! VideoReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "VideoSentTableViewCell", for: indexPath) as! VideoSentTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.audioAttachment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "AudioReceivedTableViewCell", for: indexPath) as! AudioReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "AudioSentTableViewCell", for: indexPath) as! AudioSentTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.textAttachment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "PaidMessageReceivedTableViewCell", for: indexPath) as! PaidMessageReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "PaidMessageSentTableViewCell", for: indexPath) as! PaidMessageSentTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.fileAttachment:
            if incoming {
                cell = tableView.dequeueReusableCell(withIdentifier: "FileReceivedTableViewCell", for: indexPath) as! FileReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "FileSentTableViewCell", for: indexPath) as! FileSentTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.groupLeave, TransactionMessage.TransactionMessageType.groupJoin:
            cell = tableView.dequeueReusableCell(withIdentifier: "GroupActionMessageTableViewCell", for: indexPath) as! GroupActionMessageTableViewCell
            break
        case TransactionMessage.TransactionMessageType.groupKick, TransactionMessage.TransactionMessageType.groupDelete:
            cell = tableView.dequeueReusableCell(withIdentifier: "GroupRemovedTableViewCell", for: indexPath) as! GroupRemovedTableViewCell
            break
        case TransactionMessage.TransactionMessageType.memberApprove:
            if message.chat?.isMyPublicGroup() ?? false {
                cell = tableView.dequeueReusableCell(withIdentifier: "GroupRequestTableViewCell", for: indexPath) as! GroupRequestTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "GroupActionMessageTableViewCell", for: indexPath) as! GroupActionMessageTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.memberReject:
            if message.chat?.isMyPublicGroup() ?? false {
                cell = tableView.dequeueReusableCell(withIdentifier: "GroupRequestTableViewCell", for: indexPath) as! GroupRequestTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "GroupRemovedTableViewCell", for: indexPath) as! GroupRemovedTableViewCell
            }
            break
        case TransactionMessage.TransactionMessageType.memberRequest:
            cell = tableView.dequeueReusableCell(withIdentifier: "GroupRequestTableViewCell", for: indexPath) as! GroupRequestTableViewCell
            break
        case TransactionMessage.TransactionMessageType.botResponse:
            if (message.messageContent?.isValidHTML ?? true) {
                cell = tableView.dequeueReusableCell(withIdentifier: "MessageWebViewTableViewCell", for: indexPath) as! MessageWebViewTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "MessageReceivedTableViewCell", for: indexPath) as! MessageReceivedTableViewCell
            }
            break
        default:
            break
        }
        
        return cell
    }
    
    //Row height calculation
    func getRowHeight(incoming: Bool, messageRow: TransactionMessageRow) -> CGFloat {
        var  height: CGFloat = 0.0
        let isVideoCallLink = messageRow.isVideoCallLink
        let isGiphy = messageRow.isGiphy
        let isPodcastComment = messageRow.isPodcastComment
        let isPodcastBoost = messageRow.isPodcastBoost
        
        guard let message = messageRow.transactionMessage else {
            return height
        }
        
        guard let type = messageRow.getType() else {
            return height
        }
        
        if message.isDeleted() || message.isFlagged() {
            return CommonDeletedMessageTableViewCell.getRowHeight()
        }
        
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: Int(type))
        switch (messageType) {
        case TransactionMessage.TransactionMessageType.message, TransactionMessage.TransactionMessageType.boost:
            if isVideoCallLink {
                height = CommonVideoCallTableViewCell.getRowHeight(messageRow: messageRow)
            } else if isGiphy {
                height = CommonPictureTableViewCell.getRowHeight(messageRow: messageRow)
            } else if isPodcastComment {
                height = CommonPodcastCommentTableViewCell.getRowHeight(messageRow: messageRow)
            } else if isPodcastBoost {
                height = CommonPodcastBoostTableViewCell.getRowHeight()
            } else {
                if incoming {
                    height = MessageReceivedTableViewCell.getRowHeight(messageRow: messageRow)
                } else {
                    height = MessageSentTableViewCell.getRowHeight(messageRow: messageRow)
                }
            }
        case TransactionMessage.TransactionMessageType.invoice:
            if incoming {
                if messageRow.transactionMessage.isPaid() {
                    height = PaidInvoiceReceivedTableViewCell.getRowHeight(messageRow: messageRow)
                } else if messageRow.transactionMessage.isExpired() {
                    height = ExpiredInvoiceReceivedTableViewCell.getRowHeight()
                } else {
                    height = InvoiceReceivedTableViewCell.getRowHeight(messageRow: messageRow)
                }
            } else {
                if messageRow.transactionMessage.isPaid() {
                    height = PaidInvoiceSentTableViewCell.getRowHeight(messageRow: messageRow)
                } else if messageRow.transactionMessage.isExpired() {
                    height = ExpiredInvoiceSentTableViewCell.getRowHeight()
                } else {
                    height = InvoiceSentTableViewCell.getRowHeight(messageRow: messageRow)
                }
            }
        case TransactionMessage.TransactionMessageType.payment:
            if incoming {
                height = PaymentReceivedTableViewCell.getRowHeight()
            } else {
                height = PaymentSentTableViewCell.getRowHeight()
            }
        case TransactionMessage.TransactionMessageType.confirmation:
            break
        case TransactionMessage.TransactionMessageType.cancellation:
            break
        case TransactionMessage.TransactionMessageType.directPayment:
            height = CommonDirectPaymentTableViewCell.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.imageAttachment, TransactionMessage.TransactionMessageType.pdfAttachment:
            height = CommonPictureTableViewCell.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.videoAttachment:
            height = CommonVideoTableViewCell.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.audioAttachment:
            height = CommonAudioTableViewCell.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.textAttachment:
            if incoming {
                height = PaidMessageReceivedTableViewCell.getRowHeight(messageRow: messageRow)
            } else {
                height = PaidMessageSentTableViewCell.getRowHeight(messageRow: messageRow)
            }
        case TransactionMessage.TransactionMessageType.fileAttachment:
            height = CommonFileTableViewCell.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.groupLeave, TransactionMessage.TransactionMessageType.groupJoin:
            height = GroupActionMessageTableViewCell.getRowHeight()
            break
        case TransactionMessage.TransactionMessageType.groupKick, TransactionMessage.TransactionMessageType.groupDelete:
            height = GroupRemovedTableViewCell.getRowHeight()
        case TransactionMessage.TransactionMessageType.memberApprove:
            if message.chat?.isMyPublicGroup() ?? false {
                height = GroupRequestTableViewCell.getRowHeight()
            } else {
                height = GroupActionMessageTableViewCell.getRowHeight()
            }
            break
        case TransactionMessage.TransactionMessageType.memberReject:
            if message.chat?.isMyPublicGroup() ?? false {
                height = GroupRequestTableViewCell.getRowHeight()
            } else {
                height = GroupRemovedTableViewCell.getRowHeight()
            }
            break
        case TransactionMessage.TransactionMessageType.memberRequest:
            height = GroupRequestTableViewCell.getRowHeight()
            break
        case TransactionMessage.TransactionMessageType.botResponse:
            if (message.messageContent?.isValidHTML ?? true) {
                height = MessageWebViewTableViewCell.getRowHeight(messageRow: messageRow)
            } else {
                height = MessageReceivedTableViewCell.getRowHeight(messageRow: messageRow)
            }
            break
        default:
            break
        }
        
        let heightToSubstract = getHeightToSubstract(message: messageRow.transactionMessage)
        
        if height > 0 && heightToSubstract > 0 {
            return height - heightToSubstract
        }
        return height
    }
    
    func getHeightToSubstract(message: TransactionMessage) -> CGFloat {
        let shouldRemoveHeader = message.consecutiveMessages.previousMessage && !message.isFailedOrMediaExpired()
        return shouldRemoveHeader ? CommonChatTableViewCell.kRowHeaderHeight : 0
    }
    
    func processGroupedMessages(array: [TransactionMessage], referenceMessageDate: inout Date?) {
        let filteredArray = array.filter({ !$0.isMessageReaction() })
        
        for i in 0..<filteredArray.count {
            let message = filteredArray[i]
            let nextMessage = (i + 1 < filteredArray.count) ? filteredArray[i + 1] : nil
            
            if let nextMessage = nextMessage, nextMessage.id == message.id {
                continue
            }
            
            message.resetNextConsecutiveMessages()
            if message.isUniqueOnChat() { message.resetPreviousConsecutiveMessages() }
            nextMessage?.resetPreviousConsecutiveMessages()
            
            referenceMessageDate = (referenceMessageDate == nil) ? message.date : referenceMessageDate
            
            if (nextMessage?.isNotConsecutiveMessage() ?? false) || message.isNotConsecutiveMessage() {
                referenceMessageDate = message.date
                continue
            }
            
            if referenceMessageDate!.getMinutesDifference(from: message.messageDate) > 5 {
               referenceMessageDate = message.date
            }
            
            if nextMessage != nil {
                if message.failed() || !message.isConfirmedAsReceived() {
                    referenceMessageDate = message.date
                    message.consecutiveMessages.nextMessage = false
                    nextMessage!.consecutiveMessages.previousMessage = false
                } else if referenceMessageDate!.getMinutesDifference(from: nextMessage!.messageDate) <= 5 {
                    if message.hasSameSenderThan(message: nextMessage) {
                        message.consecutiveMessages.nextMessage = true
                        nextMessage!.consecutiveMessages.previousMessage = true
                    } else {
                        referenceMessageDate = nextMessage!.date
                    }
                }
            }
        }
    }

    func processGroupedNewMessage(array: [TransactionMessage], referenceMessageDate: inout Date?, message: TransactionMessage) {
        let filteredArray = array.filter({ !$0.isMessageReaction() })
        let previousMessage = filteredArray.last
        
        referenceMessageDate = (referenceMessageDate == nil) ? message.date : referenceMessageDate
        
        if (previousMessage?.isNotConsecutiveMessage() ?? false) || message.isNotConsecutiveMessage() {
            referenceMessageDate = message.date
            return
        }
        
        if referenceMessageDate!.getMinutesDifference(from: message.messageDate) > 5 {
            referenceMessageDate = message.date
            return
        }
        
        if previousMessage != nil && referenceMessageDate!.getMinutesDifference(from: message.messageDate) <= 5 {
            if previousMessage!.failed() || !previousMessage!.isConfirmedAsReceived() {
                referenceMessageDate = message.date
                message.consecutiveMessages.previousMessage = false
                previousMessage!.consecutiveMessages.nextMessage = false
            } else if message.hasSameSenderThan(message: previousMessage) {
                message.consecutiveMessages.previousMessage = true
                previousMessage!.consecutiveMessages.nextMessage = true
            } else {
                referenceMessageDate = message.date
            }
        }
    }
    
    func processGroupedMessagesOnDelete(rowToDelete: TransactionMessageRow, previousRow: TransactionMessageRow?, nextRow: TransactionMessageRow?) -> (Bool, Bool) {
        let consecutiveMessages = rowToDelete.transactionMessage.consecutiveMessages
        if let nextRow = nextRow, !nextRow.isDayHeader && !consecutiveMessages.previousMessage && consecutiveMessages.nextMessage {
            nextRow.transactionMessage.consecutiveMessages.previousMessage = false
            return (false, true)
        }
        if let previousRow = previousRow, !previousRow.isDayHeader && consecutiveMessages.previousMessage && !consecutiveMessages.nextMessage {
            previousRow.transactionMessage.consecutiveMessages.nextMessage = false
            return (true, false)
        }
        return (false, false)
    }
    
    func processGroupedMessagesOnUpdate(updatedMessageRow: TransactionMessageRow, previousRow: TransactionMessageRow?, nextRow: TransactionMessageRow?) {
        var consecutiveMessages = updatedMessageRow.transactionMessage.consecutiveMessages
        consecutiveMessages.previousMessage = false
        consecutiveMessages.nextMessage = false
        
        if let nextRow = nextRow, !nextRow.isDayHeader {
            nextRow.transactionMessage.consecutiveMessages.previousMessage = false
        }
        if let previousRow = previousRow, !previousRow.isDayHeader {
            previousRow.transactionMessage.consecutiveMessages.nextMessage = false
        }
    }
    
    func processMessagesReactionsFor(chat: Chat?, messagesArray: [TransactionMessage], boosts: inout [String: TransactionMessage.Reactions]) {
        guard let chat = chat else {
            return
        }
        let messagesUUIDs: [String] = messagesArray.map { $0.uuid ?? "" }
        let emptyFilteredUUIDs = messagesUUIDs.filter { !$0.isEmpty }
        
        for message in TransactionMessage.getReactionsOn(chat: chat, for: emptyFilteredUUIDs) {
            processMessageReaction(
                message: message,
                owner: UserContact.getOwner(),
                contact: chat.getContact(),
                boosts: &boosts
            )
        }
    }
    
    func processMessageReaction(
        message: TransactionMessage,
        owner: UserContact?,
        contact: UserContact?,
        boosts: inout [String: TransactionMessage.Reactions]
    ) {
        if let replyUUID = message.replyUUID {
            
            let outgoing = message.isOutgoing()
            let senderImageUrl: String? = message.getMessageSenderImageUrl(owner: owner, contact: contact)
            
            let user: (String, UIColor, String?) = (message.getMessageSenderNickname(forceNickname: true), ChatHelper.getSenderColorFor(message: message), senderImageUrl)
            let amount = message.amount?.intValue ?? 0
            
            if var reaction = boosts[replyUUID] {
                reaction.add(sats: amount, user: user, id: message.id)
                if outgoing { reaction.boosted = true }
                boosts[replyUUID] = reaction
            } else {
                boosts[replyUUID] = TransactionMessage.Reactions(totalSats: amount, users: [user.0: (user.1, user.2)], boosted: outgoing, id: message.id)
            }
        }
    }
}

func getWindowInsets() -> UIEdgeInsets {
    var insets = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    if let rootWindow = UIApplication.shared.keyWindow {
        if #available(iOS 11.0, *) {
            if !UIApplication.shared.isSplitOrSlideOver {
                insets.top = rootWindow.safeAreaInsets.top
                insets.bottom = rootWindow.safeAreaInsets.bottom
            }
        }
    }
    return insets
}
