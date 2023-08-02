//
//  ThreadTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class ThreadTableDataSource : NewChatTableDataSource {
    
    var threadUUID: String!
    
    init(
        chat: Chat?,
        contact: UserContact?,
        threadUUID: String,
        tableView: UITableView,
        newMsgIndicator : NewMessagesIndicatorView,
        headerImageView: UIImageView?,
        bottomView: UIView,
        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        
        self.threadUUID = threadUUID
        
        super.init(
            chat: chat,
            contact: contact,
            tableView: tableView,
            newMsgIndicator: newMsgIndicator,
            headerImageView: headerImageView,
            bottomView: bottomView,
            webView: webView,
            delegate: delegate
        )
    }
    
    override func configureTableTransform() {
        ///Nothing to do
    }
    
    override func configureTableCellTransformOn(cell: ChatTableViewCellProtocol?) {
        ///Nothing to do
    }
    
    override func loadMoreItems() {
        ///Nothing to do
    }
    
    override func processMessages(
        messages: [TransactionMessage]
    ) {
        let chat = chat ?? contact?.getFakeChat()
        
        guard let chat = chat, let owner = owner else {
            return
        }
        
        startSearchProcess()
        
        var newMsgCount = 0
        var array: [MessageTableCellState] = []
        
        let admin = chat.getAdmin()
        let contact = chat.getConversationContact()
        
        chat.processAliasesFrom(messages: messages)
        
        let replyingMessagesMap = getReplyingMessagesMapFor(messages: messages)
        let boostMessagesMap = getBoostMessagesMapFor(messages: messages)
        let threadMessagesMap = getThreadMessagesFor(messages: messages)
        let purchaseMessagesMap = getPurchaseMessagesMapFor(messages: messages)
        let linkContactsArray = getLinkContactsArrayFor(messages: messages)
        let linkTribesArray = getLinkTribesArrayFor(messages: messages)
        
        var groupingDate: Date? = nil
        var invoiceData: (Int, Int) = (0, 0)

        for (index, message) in messages.enumerated() {
            
            invoiceData = (
                invoiceData.0 + ((message.isPayment() && message.isIncoming(ownerId: owner.id)) ? -1 : 0),
                invoiceData.1 + ((message.isPayment() && message.isOutgoing(ownerId: owner.id)) ? -1 : 0)
            )
            
            let bubbleStateAndDate = getBubbleBackgroundForMessage(
                message: message,
                with: index,
                in: messages,
                groupingDate: &groupingDate
            )
            
            if let separatorDate = bubbleStateAndDate.1 {
                array.insert(
                    MessageTableCellState(
                        chat: chat,
                        owner: owner,
                        contact: contact,
                        tribeAdmin: admin,
                        separatorDate: separatorDate,
                        invoiceData: (invoiceData.0 > 0, invoiceData.1 > 0)
                    ),
                    at: 0
                )
            }
            
            let replyingMessage = (message.replyUUID != nil) ? replyingMessagesMap[message.replyUUID!] : nil
            let boostsMessages = (message.uuid != nil) ? (boostMessagesMap[message.uuid!] ?? []) : []
            let threadMessages = (message.uuid != nil && threadUUID == nil) ? (threadMessagesMap[message.uuid!] ?? []) : []
            let purchaseMessages = purchaseMessagesMap[message.getMUID()] ?? [:]
            let linkContact = linkContactsArray[message.id]
            let linkTribe = linkTribesArray[message.id]
            let linkWeb = getLinkWebFor(message: message)
            
            let messageTableCellState = MessageTableCellState(
                message: message,
                chat: chat,
                owner: owner,
                contact: contact,
                tribeAdmin: admin,
                separatorDate: nil,
                bubbleState: bubbleStateAndDate.0,
                contactImage: headerImage,
                replyingMessage: replyingMessage,
                threadMessages:threadMessages,
                boostMessages: boostsMessages,
                purchaseMessages: purchaseMessages,
                linkContact: linkContact,
                linkTribe: linkTribe,
                linkWeb: linkWeb,
                invoiceData: (invoiceData.0 > 0, invoiceData.1 > 0)
            )
            
            array.insert(messageTableCellState, at: 0)
            
            invoiceData = (
                invoiceData.0 + ((message.isInvoice() && message.isPaid() && message.isOutgoing(ownerId: owner.id)) ? 1 : 0),
                invoiceData.1 + ((message.isInvoice() && message.isPaid() && message.isIncoming(ownerId: owner.id)) ? 1 : 0)
            )
            
            newMsgCount += getNewMessageCountFor(message: message, and: owner)
            
            processForSearch(
                message: message,
                messageTableCellState: messageTableCellState,
                index: array.count - 1
            )
        }
        
        messageTableCellStateArray = array.reversed()
        
        updateSnapshot()
        
        delegate?.configureNewMessagesIndicatorWith(
            newMsgCount: messages.count
        )
    }
    
    override func getFetchRequestFor(
        chat: Chat,
        with items: Int
    ) -> NSFetchRequest<TransactionMessage> {
        return TransactionMessage.getChatMessagesFetchRequest(
            for: chat,
            threadUUID: threadUUID,
            with: items
        )
    }
    
    override func getThreadMessagesFor(
        messages: [TransactionMessage]
    ) -> [String: [TransactionMessage]] {
        return [:]
    }
    
    override func restorePreloadedMessages() {
        ///Nothing to do
    }
    
    override func saveMessagesToPreloader() {
        ///Nothing to do
    }
    
    override func saveSnapshotCurrentState() {
        ///Nothing to do
    }
    
    override func restoreScrollLastPosition() {
        tableView.alpha = 1.0
    }
    
    override func didMoveOutOfBottomArea() {}
    
    override func didMoveOutOfTopArea() {
        scrolledAtBottom = false
        
        print("TABLE CONTENT HEIGHT \(tableView.contentSize.height)")
        print("TABLE OFFSET \(tableView.contentOffset.y)")
        print("TABLE CONTENT OFFSET \(tableView.contentSize.height - tableView.contentOffset.y)")
        
        delegate?.didScrollOutOfStartAreaWith(
            tableContentOffset: tableView.contentOffset.y - 10
        )
    }
    
    override func didScrollToBottom() {}
    
    override func didScrollToTop() {
        if scrolledAtBottom {
            return
        }
        
        scrolledAtBottom = true
        
        delegate?.didScrollToBottom()
    }
}
