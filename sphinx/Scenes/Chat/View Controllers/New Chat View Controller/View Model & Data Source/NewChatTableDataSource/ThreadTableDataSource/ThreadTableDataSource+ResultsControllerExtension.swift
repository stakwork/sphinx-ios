//
//  ThreadTableDataSource+ResultsControllerExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

extension ThreadTableDataSource {
    
    func getThreadCellFor(
        dataSourceItem: MessageTableCellState,
        indexPath: IndexPath
    ) -> UITableViewCell {

        if dataSourceItem.isThreadHeaderMessage {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "ThreadHeaderTableViewCell",
                for: indexPath
            ) as! ThreadHeaderTableViewCell
            
            let mediaData = (dataSourceItem.messageId != nil) ? self.mediaCached[dataSourceItem.messageId!] : nil
            
            cell.configureWith(
                messageCellState: dataSourceItem,
                mediaData: mediaData,
                isHeaderExpanded: self.isHeaderExpanded,
                delegate: self,
                indexPath: indexPath,
                headerDifference: headerDifference
            )
            
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            
            return cell
        }
        
        return super.getCellFor(
            dataSourceItem: dataSourceItem,
            indexPath: indexPath
        )
    }
    
    override func processMessages(
        messages: [TransactionMessage]
    ) {
        let sortedMessages = messages//.sorted(by: {$0.id < $1.id})
        let chat = chat ?? contact?.getFakeChat()
        
        guard let chat = chat, let owner = owner else {
            return
        }
        
        var array: [MessageTableCellState] = []
        
        let admin = chat.getAdmin()
        let contact = chat.getConversationContact()
        let threadOriginalMessage = TransactionMessage.getMessageWith(uuid: threadUUID)
        
        chat.processAliasesFrom(messages: sortedMessages)
        
        let replyingMessagesMap = getReplyingMessagesMapFor(messages: sortedMessages)
        let boostMessagesMap = getBoostMessagesMapFor(messages: sortedMessages)
        let threadMessagesMap = getThreadMessagesFor(messages: sortedMessages)
        let purchaseMessagesMap = getPurchaseMessagesMapFor(messages: sortedMessages)
        let linkContactsArray = getLinkContactsArrayFor(messages: sortedMessages)
        let linkTribesArray = getLinkTribesArrayFor(messages: sortedMessages)
        let webLinksArray = getWebLinksArrayFor(messages: sortedMessages)
        
        var groupingDate: Date? = nil
        var invoiceData: (Int, Int) = (0, 0)

        for (index, message) in sortedMessages.enumerated() {
            
            invoiceData = (
                invoiceData.0 + ((message.isPayment() && message.isIncoming(ownerId: owner.id)) ? -1 : 0),
                invoiceData.1 + ((message.isPayment() && message.isOutgoing(ownerId: owner.id)) ? -1 : 0)
            )
            
            let bubbleStateAndDate = getBubbleBackgroundForMessage(
                msg: message,
                with: index,
                in: sortedMessages,
                and: [:],
                groupingDate: &groupingDate,
                threadHeaderMessage: threadOriginalMessage
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
            let linkWeb = webLinksArray[message.id]
            
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
                threadMessages: threadMessages,
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
        }
        
        if let threadOriginalMessage = threadOriginalMessage {
            let boostMessagesMap = getBoostMessagesMapFor(messages: [threadOriginalMessage])
            let boostsMessages = (threadOriginalMessage.uuid != nil) ? (boostMessagesMap[threadOriginalMessage.uuid!] ?? []) : []
            
            array.append(
                MessageTableCellState(
                    message: threadOriginalMessage,
                    chat: chat,
                    owner: owner,
                    contact: contact,
                    tribeAdmin: admin,
                    bubbleState: MessageTableCellState.BubbleState.Isolated,
                    boostMessages: boostsMessages,
                    isThreadHeaderMessage: true
                )
            )
        }
        
        messageTableCellStateArray = array
        
        updateSnapshot()
        
        delegate?.configureNewMessagesIndicatorWith(
            newMsgCount: sortedMessages.count
        )
        
        delegate?.shouldReloadThreadHeaderView()
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
}
