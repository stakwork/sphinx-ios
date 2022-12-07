//
//  Library
//
//  Created by Tomas Timinskas on 09/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

protocol ChatDataSourceDelegate: class {
    func didScrollToBottom()
    func didDeleteGroup()
    func chatUpdated(chat: Chat)
}

class ChatDataSource : NSObject {
    var delegate: ChatDataSourceDelegate?
    var cellDelegate: MessageCellDelegate?
    
    var contact: UserContact? = nil
    var chat: Chat? = nil
    var tribeAdmin: UserContact? = nil
    var contactIdsDictionary = [Int: UserContact] ()
    
    var chatMessagesCount = 0
    var messagesArray = [TransactionMessage]()
    var messageRowsArray = [TransactionMessageRow]()
    var messageIdsArray = [Int]()
    var boosts: [String: TransactionMessage.Reactions] = [String: TransactionMessage.Reactions]()
    var tableView : UITableView!
    
    var indexesToInsert = [IndexPath]()
    var indexesToUpdate = [IndexPath]()
    
    var userId : Int = -1
    var page = 1
    var itemsPerPage = 50
    var insertedRowsCount = 0
    var insertingRows = false
    
    var paymentForInvoiceReceived: Bool = false
    var paymentForInvoiceSent: Bool = false
    var paymentHashForInvoiceSent: String? = nil
    var paymentHashForInvoiceReceived: String? = nil
    
    var chatHelper = ChatHelper()
    var referenceMessageDate:Date? = nil
    
    init(tableView: UITableView, delegate: ChatDataSourceDelegate, cellDelegate: MessageCellDelegate) {
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        self.cellDelegate = cellDelegate
        self.userId = UserData.sharedInstance.getUserId()
    }
    
    func setDataAndReload(contact: UserContact? = nil, chat: Chat? = nil, forceReload: Bool = false) {
        self.contact = contact
        self.chat = chat
        self.tribeAdmin = UserContact.getContactWith(pubkey: chat?.ownerPubkey ?? "")
        
        let newMessagesCount = (chat?.getNewMessagesCount(lastMessageId: self.messageIdsArray.last) ?? 0)
        if newMessagesCount == 0 && messagesArray.count > 0 && !forceReload {
            return
        }
        
        itemsPerPage = getInitialItemsPerPage() + newMessagesCount
        
        referenceMessageDate = nil
        resetLastInvoices()
        page = 1
        insertingRows = false
        insertedRowsCount = 0
        
        chatMessagesCount = chat?.getAllMessagesCount() ?? 0
        messagesArray = chat?.getAllMessages(limit: itemsPerPage) ?? [TransactionMessage]()
        messageIdsArray = []
        messageRowsArray = []
        boosts = [:]
        createContactIdsDictionary()
        
        chatHelper.processMessagesReactionsFor(chat: chat, messagesArray: messagesArray, boosts: &boosts)
        processMessagesArray(newObjectsCount: messagesArray.count)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func getInitialItemsPerPage() -> Int {
        if messagesArray.count > 0 {
            return messagesArray.count
        }
        return itemsPerPage
    }
    
    func createContactIdsDictionary() {
        contactIdsDictionary = [Int: UserContact] ()
        
        if let chat = chat {
            for c in chat.getContacts() {
                contactIdsDictionary[c.id] = c
            }
        } else if let contact = contact {
            contactIdsDictionary[contact.id] = contact
        }
    }
    
    func getContactFor(messageRow: TransactionMessageRow) -> UserContact? {
        var messageContact = self.contact
        if let senderId = messageRow.transactionMessage?.senderId, let sender = contactIdsDictionary[senderId] {
            messageContact = sender
        }
        return messageContact
    }
    
    func updateContact(contact: UserContact) {
        self.contact = contact
        self.chat = contact.getChat()
    }
    
    func resetLastInvoices() {
        paymentForInvoiceReceived = false
        paymentForInvoiceSent = false
        paymentHashForInvoiceSent = nil
        paymentHashForInvoiceReceived = nil
    }
    
    func processMessagesArray(newObjectsCount: Int) {
        chatHelper.processGroupedMessages(array: messagesArray, referenceMessageDate: &referenceMessageDate)
        
        self.chat?.aliases = Array(Set(messagesArray.compactMap({$0.senderAlias})))
        
        let limit = 0
        let start = newObjectsCount - 1
        
        for x in stride(from: start, through: limit, by: -1) {
            let message = messagesArray[x]
            
            if message.isUnknownType() || message.isMessageReaction() {
                continue
            }
            
            message.addPurchaseItems()
            message.reactions = boosts[message.uuid ?? ""]
            
            let previousMessage = x - 1 >= limit ? messagesArray[x - 1] : nil

            message.uploadingObject = nil
            
            let messageRow = TransactionMessageRow(message: message)

            let messageType = Int(message.type)
            switch (messageType) {
            case TransactionMessage.TransactionMessageType.invoice.rawValue:
                let incoming = message.isIncoming()
                let paymentHash = incoming ? paymentHashForInvoiceReceived : paymentHashForInvoiceSent
                if let invoicePaymentHash = message.paymentHash, let paymentHash = paymentHash, invoicePaymentHash == paymentHash {
                    if incoming {
                        paymentForInvoiceReceived = false
                        paymentHashForInvoiceReceived = nil
                    } else {
                        paymentForInvoiceSent = false
                        paymentHashForInvoiceSent = nil
                    }
                }
                break
            case TransactionMessage.TransactionMessageType.payment.rawValue:
                let isPaid = message.isPaid()
                if message.isIncoming() {
                    paymentForInvoiceSent = isPaid ? true : paymentForInvoiceSent
                    paymentHashForInvoiceSent = isPaid ? message.paymentHash : nil
                } else {
                    paymentForInvoiceReceived = isPaid ? true : paymentForInvoiceReceived
                    paymentHashForInvoiceReceived = isPaid ? message.paymentHash : nil
                }
                break
            default:
                break
            }
            
            messageRow.shouldShowRightLine = paymentForInvoiceReceived
            messageRow.shouldShowLeftLine = paymentForInvoiceSent

            let id = Int(message.id)
            if !messageIdsArray.contains(id) {
                messageRowsArray.insert(messageRow, at: 0)
                messageIdsArray.insert(id, at: 0)
            }
            
            if TransactionMessage.isDifferentDayMessage(lastMessage: message, newMessage: previousMessage) {
                messageRowsArray.insert(getDayHeaderRow(date: message.date), at: 0)
            }
            
            if x == limit {
                if chatMessagesCount > messagesArray.count {
                    let loadingMoreRow = TransactionMessageRow()
                    messageRowsArray.insert(loadingMoreRow, at: 0)
                } else {
                    let dayHeaderRow = TransactionMessageRow()
                    dayHeaderRow.headerDate = message.date
                    messageRowsArray.insert(dayHeaderRow, at: 0)
                }
            }
        }
    }
    
    func showMoreMessages() {
        itemsPerPage = 50
        let newMessages = chat?.getAllMessages(limit: itemsPerPage, lastMessage: messagesArray[0]) ?? [TransactionMessage]()
        
        if newMessages.count > 0 {
            chatHelper.processMessagesReactionsFor(chat: chat, messagesArray: newMessages, boosts: &boosts)
            messagesArray.insert(contentsOf: newMessages, at: 0)
            
            insertObjectsToModel(newObjectsCount: newMessages.count)
            appendCells()
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
                self.insertingRows = false
            }
        }
    }
    
    func insertObjectsToModel(newObjectsCount: Int) {
        page = page + 1
        messageRowsArray.remove(at: 0)
        processMessagesArray(newObjectsCount: newObjectsCount)
    }
    
    func appendCells() {
        let oldContentHeight = tableView.contentSize.height
        let oldOffsetY = tableView.contentOffset.y
        tableView.reloadData()
        let newContentHeight: CGFloat = tableView.contentSize.height
        tableView.contentOffset.y = oldOffsetY + (newContentHeight - oldContentHeight)
    }
    
    func getMessageRowToUpdate(m: TransactionMessage) -> (Int, TransactionMessageRow)? {
        let limit = messageRowsArray.count > itemsPerPage ? itemsPerPage : messageRowsArray.count
        for (index, messageRow) in messageRowsArray.enumerated().reversed()[0..<limit] {
            if let message = messageRow.transactionMessage {
                if message.id == m.id {
                    return (index, messageRow)
                }
            }
        }
        return nil
    }
    
    func scrollTo(message: TransactionMessage) {
        if let messageRowToUpdate = getMessageRowToUpdate(m: message) {
            tableView.scrollToRow(at: IndexPath(row: messageRowToUpdate.0, section: 0), at: .bottom, animated: true)
        }
    }
    
    func isDifferentChat(message: TransactionMessage, vcChat: Chat?) -> Bool {
        if let chat = vcChat, let messageChatId = message.chat?.id, chat.id == messageChatId {
            return false
        }
        return true
    }
    
    func reloadAttachmentRow(m: TransactionMessage) -> IndexPath? {
        let limit = messageRowsArray.count > itemsPerPage ? itemsPerPage : messageRowsArray.count
        for (index, messageRow) in messageRowsArray.enumerated().reversed()[0..<limit] {
            if let message = messageRow.transactionMessage {
                let mMUID = m.getMUID()
                let originalMUID = m.originalMuid ?? ""
                let messageMUID = message.getMUID()
                
                if !messageMUID.isEmpty && !mMUID.isEmpty && (messageMUID == mMUID || messageMUID == originalMUID) {
                    
                    message.addPurchaseItems()
                    messageRow.transactionMessage = message
                    
                    let indexToReload = IndexPath(row: index, section: 0)
                    tableView.reloadRows(at: [indexToReload], with: .none)
                    return indexToReload
                }
            }
        }
        return nil
    }
    
    func processIncomingBoost(message: TransactionMessage) {
        chatHelper.processMessageReaction(
            message: message,
            owner: UserContact.getOwner(),
            contact: self.chat?.getContact(),
            boosts: &boosts
        )
        
        if let boostedMessage = message.getReplyingTo() {
            boostedMessage.reactions = boosts[message.replyUUID ?? ""]
            addMessageAndReload(message: boostedMessage)
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 1, completion: {
            NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
        })
    }
    
    func addMessageAndReload(message: TransactionMessage, provisional: Bool = false, confirmation: Bool = false) {
        if isDifferentChat(message: message, vcChat: self.chat) {
            return
        }
        
        if message.isUnknownType() {
            return
        }
        
        if message.isMessageReaction() {
            processIncomingBoost(message: message)
            return
        }
        
        var messageRowToUpdate : (Int, TransactionMessageRow)? = nil
        messageRowToUpdate = getMessageRowToUpdate(m: message)
        
        let id = Int(message.id)
        
        if let messageRowToUpdate = messageRowToUpdate {
            messageRowToUpdate.1.transactionMessage = message
            
            if !self.messageIdsArray.contains(id) {
                self.messagesArray.append(message)
                self.messageIdsArray.append(id)
            }
            
            let indexes = getIndexesToUpdateOnUpdate(index: messageRowToUpdate.0)
            indexesToUpdate.append(contentsOf: indexes)
        } else if confirmation {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.addMessageAndReload(message: message, provisional: provisional, confirmation: false)
            })
            return
        } else {
            let messageRow = TransactionMessageRow(message: message)
            
            if !self.messageIdsArray.contains(id) {
                
                if TransactionMessage.isDifferentDay(lastMessage: messagesArray.last, newMessageDate: message.date) {
                    messageRowsArray.append(getDayHeaderRow(date: message.date))
                    indexesToInsert.append(IndexPath(row: self.messageRowsArray.count - 1, section: 0))
                }
                
                self.chatHelper.processGroupedNewMessage(array: messagesArray, referenceMessageDate: &referenceMessageDate, message: messageRow.transactionMessage)
                self.messageRowsArray.append(messageRow)
                
                if id >= 0 {
                    self.messagesArray.append(message)
                    self.messageIdsArray.append(id)
                }
                
                indexesToInsert.append(IndexPath(row: self.messageRowsArray.count - 1, section: 0))
            }
        }
        
        if indexesToInsert.count == 0 && indexesToUpdate.count == 0 {
            return
        }
        
        DispatchQueue.main.async {
            self.insertAndUpdateRows(provisional: provisional)
        }
    }
    
    func reloadPreviousRow(row: Int) {
        let previousIndex = (row - 1 >= 0) ? IndexPath(row: row - 1, section: 0) : nil
        
        if let previousIndex = previousIndex {
            let currentMessage = messageRowsArray[row].transactionMessage
            let previousMessage = messageRowsArray[previousIndex.row].transactionMessage
             
             if currentMessage?.isOutgoing() ?? false && previousMessage?.isIncoming() ?? false {
                return
            }
            
            tableView.reloadRows(at: [previousIndex], with: .none)
        }
    }
    
    func insertAndUpdateRows(provisional: Bool) {
        if indexesToInsert.count > 0 {
            if shouldInsertRows() {
                insertedRowsCount = insertedRowsCount + indexesToInsert.count
                tableView.beginUpdates()
                tableView.insertRows(at: indexesToInsert, with: .none)
                tableView.endUpdates()
                
                reloadPreviousRow(row: indexesToInsert[0].row)
            }
            
            indexesToInsert = [IndexPath]()
            
            if provisional {
                tableView.scrollToBottom(animated: false)
            }
        }
        
        if indexesToUpdate.count > 0 {
            tableView.reloadRows(at: indexesToUpdate, with: getUpdateRowAnimation(indexes: indexesToUpdate))
            indexesToUpdate = [IndexPath]()
        }
    }
    
    func getUpdateRowAnimation(indexes: [IndexPath]) -> UITableView.RowAnimation {
        var animation: UITableView.RowAnimation = .none
        
        for index in indexes {
            let messageRow = messageRowsArray[index.row]
            if messageRow.transactionMessage?.isDeleted() ?? false {
                animation = .fade
            }
        }
        
        return animation
    }
    
    func shouldInsertRows() -> Bool {
        return messageRowsArray.count == tableView.numberOfRows(inSection: 0) + indexesToInsert.count
    }
    
    func getDayHeaderRow(date: Date?) -> TransactionMessageRow {
        let dayHeaderRow = TransactionMessageRow()
        dayHeaderRow.headerDate = date ?? Date()
        return dayHeaderRow
    }
    
    func getLoadingRow() -> TransactionMessageRow {
        let dayHeaderRow = TransactionMessageRow()
        return dayHeaderRow
    }
    
    func deleteCellFor(m: TransactionMessage) {
        for (index, messageRow) in self.messageRowsArray.enumerated().reversed() {
            if let message = messageRow.transactionMessage {
                if message.id == m.id {
                    deleteObjectWith(id: m.id, and: index)
                    return
                }
            }
        }
    }
    
    func updateRowForMessage(_ m: TransactionMessage) {
        for (index, messageRow) in self.messageRowsArray.enumerated().reversed() {
            if let message = messageRow.transactionMessage {
                if message.id == m.id {
                    let indexesToUpdate = getIndexesToUpdateOnUpdate(index: index)
                    
                    tableView.beginUpdates()
                    tableView.reloadRows(at: indexesToUpdate, with: .fade)
                    tableView.endUpdates()
                    break
                }
            }
        }
    }
    
    func deleteObjectWith(id: Int, and index: Int) {
        let consecutiveRows = getPreviousAndNextRows(index: index)
        updatePreviousAndNext(index: index, consecutiveRows: consecutiveRows)
        
        messagesArray = messagesArray.filter { $0.id != id }
        messageIdsArray = messageIdsArray.filter {$0 != id }
        
        let indexPathsToRemove = getIndexPathsToRemove(index: index, consecutiveRows: consecutiveRows)
        
        for index in indexPathsToRemove {
            messageRowsArray.remove(at: index.row)
        }
        
        insertedRowsCount = insertedRowsCount - indexPathsToRemove.count
        chatMessagesCount = chatMessagesCount - 1
        
        tableView.beginUpdates()
        tableView.deleteRows(at: indexPathsToRemove, with: .none)
        tableView.endUpdates()
    }
    
    func getIndexPathsToRemove(index: Int, consecutiveRows: (TransactionMessageRow?, TransactionMessageRow?)) -> [IndexPath] {
        var indexPathsToRemove = [IndexPath(row: index, section: 0)]
        
        if let previousRow = consecutiveRows.0, previousRow.isDayHeader {
            if consecutiveRows.1 == nil || (consecutiveRows.1?.isDayHeader ?? false) {
                indexPathsToRemove.append(IndexPath(row: index - 1, section: 0))
            }
        }
        
        return indexPathsToRemove
    }
    
    func updatePreviousAndNext(index: Int, consecutiveRows: (TransactionMessageRow?, TransactionMessageRow?)) {
        let (shouldUpdatePrev, shouldUpdateNext) = chatHelper.processGroupedMessagesOnDelete(rowToDelete: messageRowsArray[index], previousRow: consecutiveRows.0, nextRow: consecutiveRows.1)
        
        if shouldUpdatePrev {
            tableView.reloadRows(at: [IndexPath(row: index - 1, section: 0)], with: .none)
        } else if shouldUpdateNext {
            tableView.reloadRows(at: [IndexPath(row: index + 1, section: 0)], with: .none)
        }
    }
    
    func getIndexesToUpdateOnUpdate(index: Int) -> [IndexPath] {
        var indexes: [IndexPath] = []
        indexes.append(IndexPath(row: index, section: 0))
        
        if !(messageRowsArray[index].transactionMessage?.isDeleted() ?? false) {
            return indexes
        }
        
        let consecutiveRows = getPreviousAndNextRows(index: index)
        chatHelper.processGroupedMessagesOnUpdate(updatedMessageRow: messageRowsArray[index], previousRow: consecutiveRows.0, nextRow: consecutiveRows.1)
        
        if let _ = consecutiveRows.0 {
            indexes.append(IndexPath(row: index - 1, section: 0))
        }
        if let _ = consecutiveRows.1 {
            indexes.append(IndexPath(row: index + 1, section: 0))
        }
        return indexes
    }
    
    func getPreviousAndNextRows(index: Int) -> (TransactionMessageRow?, TransactionMessageRow?) {
        let previousRow = (index > 0) ? messageRowsArray[index - 1] : nil
        let nextRow = (index < messageRowsArray.count - 1) ? messageRowsArray[index + 1] : nil
        return (previousRow, nextRow)
    }
}

extension ChatDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return getHeighForRowAt(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return getHeighForRowAt(indexPath: indexPath)
    }
    
    func getHeighForRowAt(indexPath: IndexPath) -> CGFloat {
        let messageRow = messageRowsArray[indexPath.row]
        
        guard let _ = messageRow.getType() else {
            if let _  = messageRow.headerDate {
                return DayHeaderTableViewCell.kHeaderHeight
            } else {
                return LoadingMoreTableViewCell.kLoadingHeight
            }
        }
        
        let incoming = messageRow.isIncoming()
        let height: CGFloat = chatHelper.getRowHeight(incoming: incoming, messageRow: messageRow)
        return height
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let messageRow = messageRowsArray[indexPath.row]
        let sender = getContactFor(messageRow: messageRow)
        
        if let cell = cell as? DayHeaderTableViewCell {
            cell.configureCell(messageRow: messageRow)
        } else if let cell = cell as? LoadingMoreTableViewCell {
            cell.configureCell(text: "loading.more.messages".localized)
        } else if let cell = cell as? MessageRowProtocol {
            cell.configureMessageRow(
                messageRow: messageRow,
                contact: sender,
                chat: chat
            )
            cell.delegate = cellDelegate
            cell.audioDelegate = self
        } else if let cell = cell as? GroupActionRowProtocol {
            cell.configureMessage(message: messageRow.transactionMessage)
            cell.delegate = self
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? RowWithLinkPreviewProtocol {
            cell.rowWillDisappear()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.setSelected(false, animated: false)
            
            let message = messageRowsArray[indexPath.row]
            
            if let _ = cell as? CommonPictureTableViewCell, message.transactionMessage.isAttachmentAvailable() {
                cellDelegate?.didTapAttachmentRow(message: message.transactionMessage)
            }
        }
    }
}

extension ChatDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageRowsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageRow = messageRowsArray[indexPath.row]
        return chatHelper.getCellFor(messageRow: messageRow, indexPath: indexPath, on: tableView)
    }
}

extension ChatDataSource : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height - 50) {
            delegate?.didScrollToBottom()
        }
        
        if scrollView.contentOffset.y <= LoadingMoreTableViewCell.kLoadingHeight && !insertingRows {
            if chatMessagesCount <= messagesArray.count {
                return
            }
            
            insertingRows = true
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.showMoreMessages()
            })
        }
    }
}

extension ChatDataSource : AudioCellDelegate {
    func shouldStopPlayingAudios(cell: AudioCollectionViewItem?) {
        var cellIndexPathRow = -1
        if let cell = cell as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            cellIndexPathRow = indexPath.row
        }
        
        for vc in self.tableView.visibleCells {
            if let ip = tableView.indexPath(for: vc), let vc = vc as? CommonAudioTableViewCell, ip.row != cellIndexPathRow {
                vc.stopPlaying()
            }
        }
    }
}

extension ChatDataSource : GroupRowDelegate {
    func shouldDeleteGroup() {
        let isPublicGroup = chat?.isPublicGroup() ?? false
        let deleteTitle = (isPublicGroup ? "delete.tribe" : "delete.group").localized
        let deleteMessage = (isPublicGroup ? "confirm.delete.tribe" : "confirm.delete.group").localized
        
        AlertHelper.showTwoOptionsAlert(title: deleteTitle, message: deleteMessage, confirm: {
            self.deleteGroup()
        })
    }
    
    func deleteGroup() {
        let bubbleHelper = NewMessageBubbleHelper()
        bubbleHelper.showLoadingWheel()
        
        GroupsManager.sharedInstance.deleteGroup(chat: self.chat, completion: { success in
            bubbleHelper.hideLoadingWheel()
            
            if success {
                self.delegate?.didDeleteGroup()
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        })
    }
    
    func shouldApproveMember(requestMessage: TransactionMessage) {
        respondToRequest(message: requestMessage, action: "approved", completion: { (chat, message) in
            self.delegate?.chatUpdated(chat: chat)
            self.addMessageAndReload(message: message)
        })
    }
    
    func shouldRejectMember(requestMessage: TransactionMessage) {
        respondToRequest(message: requestMessage, action: "rejected", completion: { (chat, message) in
            self.delegate?.chatUpdated(chat: chat)
            self.addMessageAndReload(message: message)
        })
    }
    
    func respondToRequest(message: TransactionMessage, action: String, completion: @escaping (Chat, TransactionMessage) -> ()) {
        API.sharedInstance.requestAction(messageId: message.id, contactId: message.senderId, action: action, callback: { json in
            if let chat = Chat.insertChat(chat: json["chat"]), let message = TransactionMessage.insertMessage(m: json["message"]).0 {
                completion(chat, message)
                return
            }
            self.processingRequestFailed()
        }, errorCallback: {
            self.processingRequestFailed()
        })
    }
    
    func processingRequestFailed() {
        NewMessageBubbleHelper().hideLoadingWheel()
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
}
