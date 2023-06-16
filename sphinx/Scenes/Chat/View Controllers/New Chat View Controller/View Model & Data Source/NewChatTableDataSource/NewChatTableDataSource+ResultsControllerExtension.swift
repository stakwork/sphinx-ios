//
//  NewChatTableDataSource+ResultsControllerExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

extension NewChatTableDataSource {
    
    enum CollectionViewSection: Int, CaseIterable {
        case messages
    }

    typealias BubbleCell = NewMessageTableViewCell
    typealias NoBubbleCell = MessageNoBubbleTableViewCell
    
    typealias DataSource = UITableViewDiffableDataSource<CollectionViewSection, MessageTableCellState>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, MessageTableCellState>
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: self.tableView,
            cellProvider: makeCellProvider(for: self.tableView)
        )

        return dataSource
    }

    func configureDataSource() {
        dataSource = makeDataSource()

        restorePreloadedMessages()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: { [weak self] in
            guard let self = self else { return }
            self.configureResultsController(items: max(self.dataSource.snapshot().numberOfItems, 100))
        })
    }
    
    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections([CollectionViewSection.messages])

        snapshot.appendItems(
            messageTableCellStateArray,
            toSection: .messages
        )

        return snapshot
    }
    
    func updateSnapshot() {
        let snapshot = makeSnapshotForCurrentState()

        DispatchQueue.main.async {
            self.saveSnapshotCurrentState()
            self.dataSource.apply(snapshot, animatingDifferences: false)
            self.tableView.alpha = 1.0
            self.restoreScrollLastPosition()
            self.loadingMoreItems = false
        }
    }
    
    func makeCellProvider(
        for tableView: UITableView
    ) -> DataSource.CellProvider {
        { (tableView, indexPath, dataSourceItem) -> UITableViewCell in
            
            var cell: ChatTableViewCellProtocol? = nil
            var mutableDataSourceItem = dataSourceItem
            
            if let _ = mutableDataSourceItem.bubble {
                if mutableDataSourceItem.isTextOnlyMessage {
                    cell = tableView.dequeueReusableCell(
                        withIdentifier: "NewOnlyTextMessageTableViewCell",
                        for: indexPath
                    ) as! NewOnlyTextMessageTableViewCell
                } else {
                    cell = tableView.dequeueReusableCell(
                        withIdentifier: "NewMessageTableViewCell",
                        for: indexPath
                    ) as! NewMessageTableViewCell
                }
            } else {
                cell = tableView.dequeueReusableCell(
                    withIdentifier: "MessageNoBubbleTableViewCell",
                    for: indexPath
                ) as! MessageNoBubbleTableViewCell
            }
            
            let mediaData = (dataSourceItem.messageId != nil) ? self.cachedMedia[dataSourceItem.messageId!] : nil
            let tribeData = (dataSourceItem.linkTribe?.uuid != nil) ? self.preloaderHelper.tribesData[dataSourceItem.linkTribe!.uuid] : nil
            
            cell?.configureWith(
                messageCellState: dataSourceItem,
                mediaData: mediaData,
                tribeData: tribeData,
                delegate: self,
                indexPath: indexPath
            )
            
            cell?.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            
            return (cell as? UITableViewCell) ?? UITableViewCell()
        }
    }
}

extension NewChatTableDataSource {
    
    func processMessages(
        messages: [TransactionMessage]
    ) {
        guard let owner = UserContact.getOwner() else {
            return
        }
        
        var newMsgCount = 0
        var array: [MessageTableCellState] = []
        
        let admin = chat.getAdmin()
        let contact = chat.getConversationContact()
        
        let replyingMessagesMap = getReplyingMessagesMapFor(messages: messages)
        let boostMessagesMap = getBoostMessagesMapFor(messages: messages)
        let linkContactsArray = getLinkContactsArrayFor(messages: messages)
        let linkTribesArray = getLinkTribesArrayFor(messages: messages)
        
        var groupingDate: Date? = nil

        for (index, message) in messages.enumerated() {
            if message.shouldShowOnChat() {
                
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
                            separatorDate: separatorDate
                        ),
                        at: 0
                    )
                }
                
                let replyingMessage = (message.replyUUID != nil) ? replyingMessagesMap[message.replyUUID!] : nil
                let boostsMessages = (message.uuid != nil) ? (boostMessagesMap[message.uuid!] ?? []) : []
                let linkContact = linkContactsArray[message.id]
                let linkTribe = linkTribesArray[message.id]
                
                array.insert(
                    MessageTableCellState(
                        message: message,
                        chat: chat,
                        owner: owner,
                        contact: contact,
                        tribeAdmin: admin,
                        separatorDate: nil,
                        bubbleState: bubbleStateAndDate.0,
                        contactImage: headerImage,
                        replyingMessage: replyingMessage,
                        boostMessages: boostsMessages,
                        linkContact: linkContact,
                        linkTribe: linkTribe
                    ),
                    at: 0
                )
                
                newMsgCount += getNewMessageCountFor(message: message, and: owner)
            }
        }
        
        messageTableCellStateArray = array
        
        updateSnapshot()
        
        delegate?.configureNewMessagesIndicatorWith(newMsgCount: newMsgCount)
    }
    
    private func getNewMessageCountFor(
        message: TransactionMessage,
        and owner: UserContact
    ) -> Int {
        if (message.isIncoming(ownerId: owner.id) && !message.seen && !chat.seen) {
            return 1
        }
        return 0
    }
    
    private func getBubbleBackgroundForMessage(
        message: TransactionMessage,
        with index: Int,
        in messages: [TransactionMessage],
        groupingDate: inout Date?
    ) -> (MessageTableCellState.BubbleState?, Date?) {
        
        let previousMessage = (index > 0) ? messages[index - 1] : nil
        let nextMessage = (index < messages.count - 1) ? messages[index + 1] : nil
        
        var separatorDate: Date? = nil
        
        if let previousMessageDate = previousMessage?.date, let date = message.date {
            if Date.isDifferentDay(firstDate: previousMessageDate, secondDate: date) {
                separatorDate = date
            }
        } else if previousMessage == nil {
            separatorDate = message.date
        }
        
        if message.isDeleted() || message.isGroupActionMessage() {
            return (nil, separatorDate)
        }
        
        let groupingMinutesLimit = 5
        let messageDate = message.date ?? Date(timeIntervalSince1970: 0)
        var date = groupingDate ?? messageDate

        let shouldAvoidGroupingWithPrevious = (previousMessage?.shouldAvoidGrouping() ?? true) || message.shouldAvoidGrouping()
        let isGroupedBySenderWithPrevious = previousMessage?.hasSameSenderThanMessage(message) ?? false
        let isGroupedByDateWithPrevious = messageDate.getMinutesDifference(from: date) < groupingMinutesLimit
        let groupedWithPrevious = (!shouldAvoidGroupingWithPrevious && isGroupedBySenderWithPrevious && isGroupedByDateWithPrevious)

        date = (groupedWithPrevious) ? date : messageDate

        let shouldAvoidGroupingWithNext = (nextMessage?.shouldAvoidGrouping() ?? true) || message.shouldAvoidGrouping()
        let isGroupedBySenderWithNext = nextMessage?.hasSameSenderThanMessage(message) ?? false
        let isGroupedByDateWithNext = (nextMessage != nil) ? (nextMessage?.date?.getMinutesDifference(from: date) ?? 0) < groupingMinutesLimit : false
        let groupedWithNext = (!shouldAvoidGroupingWithNext && isGroupedBySenderWithNext && isGroupedByDateWithNext)

        groupingDate = date
        
        if !groupedWithPrevious && !groupedWithNext {
            return (MessageTableCellState.BubbleState.Isolated, separatorDate)
        } else if groupedWithPrevious && !groupedWithNext {
            return (MessageTableCellState.BubbleState.Last, separatorDate)
        } else if !groupedWithPrevious && groupedWithNext {
            return (MessageTableCellState.BubbleState.First, separatorDate)
        } else if groupedWithPrevious && groupedWithNext {
            return (MessageTableCellState.BubbleState.Middle, separatorDate)
        }
        return (MessageTableCellState.BubbleState.Isolated, separatorDate)
    }
    
    func getReplyingMessagesMapFor(
        messages: [TransactionMessage]
    ) -> [String: TransactionMessage] {
        
        let replayingUUIDs: [String] = messages.map({ $0.replyUUID ?? "" }).filter({ $0.isNotEmpty })
        let replyingMessages = TransactionMessage.getMessagesWith(uuids: replayingUUIDs)
        var replyingMessagesMap: [String: TransactionMessage] = [:]
        
        replyingMessages.map({ ( ($0.uuid ?? "-"), $0) }).forEach {
            replyingMessagesMap[$0.0] = $0.1
        }
        
        return replyingMessagesMap
    }
    
    func getBoostMessagesMapFor(
        messages: [TransactionMessage]
    ) -> [String: [TransactionMessage]] {
        let messageUUIDs: [String] = messages.map({ $0.uuid ?? "" }).filter({ $0.isNotEmpty })
        let boostMessages = TransactionMessage.getBoostMessagesFor(messageUUIDs, on: chat)
        
        var boostMessagesMap: [String: [TransactionMessage]] = [:]
        
        for boostMessage in boostMessages {
            if let replyUUID = boostMessage.replyUUID, replyUUID.isNotEmpty {
                if let map = boostMessagesMap[replyUUID], map.count > 0 {
                    boostMessagesMap[replyUUID]?.append(boostMessage)
                } else {
                    boostMessagesMap[replyUUID] = [boostMessage]
                }
            }
        }
        
        return boostMessagesMap
    }
    
    func getLinkContactsArrayFor(
        messages: [TransactionMessage]
    ) -> [Int: MessageTableCellState.LinkContact] {
        
        var pubkeys: [Int: (String, String?)] = [:]
        
        messages.forEach({
            if $0.messageContent?.hasPubkeyLinks == true {
                pubkeys[$0.id] = (
                    $0.messageContent?.stringFirstPubKey?.pubkeyComponents.0 ?? "",
                    $0.messageContent?.stringFirstPubKey?.pubkeyComponents.1
                )
            }
        })
        
        let contacts = UserContact.getContactsWith(pubkeys: Array(pubkeys.values.map({ $0.0 })))
        var linkContactsMap: [Int: MessageTableCellState.LinkContact] = [:]
        
        pubkeys.forEach({ (key, value) in
            linkContactsMap[key] = MessageTableCellState.LinkContact(
                pubkey: value.0,
                routeHint: value.1,
                contact: contacts.filter({ $0.publicKey == value.0 }).first
            )
        })
        
        return linkContactsMap
    }
    
    
    func getLinkTribesArrayFor(
        messages: [TransactionMessage]
    ) -> [Int: MessageTableCellState.LinkTribe] {
        
        var linksAndUUIDs: [Int: (String, String)] = [:]
        
        messages.forEach({
            if $0.messageContent?.hasTribeLinks == true {
                if let link = $0.messageContent?.stringFirstTribeLink {
                    if let uuid = GroupsManager.sharedInstance.getGroupInfo(query: link)?.uuid {
                        linksAndUUIDs[$0.id] = (link, uuid)
                    }
                }
            }
        })
        
        let chats = Chat.getChatsWith(uuids: linksAndUUIDs.values.map({ $0.1 }))
        
        var linkTribesMap: [Int: MessageTableCellState.LinkTribe] = [:]
        
        linksAndUUIDs.forEach({ (key, value) in
            linkTribesMap[key] = MessageTableCellState.LinkTribe(
                link: value.0,
                uuid: value.1,
                isJoined: chats.filter({ $0.uuid == value.1 }).count > 0
            )
        })
        
        return linkTribesMap
    }
}

extension NewChatTableDataSource : NSFetchedResultsControllerDelegate {
    
    func startListeningToResultsController() {
        messagesResultsController?.delegate = self
    }
    
    func stopListeningToResultsController() {
        messagesResultsController?.delegate = nil
    }
    
    func configureResultsController(items: Int) {
        messagesCount = items
        
        let fetchRequest = TransactionMessage.getChatMessagesFetchRequest(
            for: chat,
            with: items
        )

        messagesResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        messagesResultsController.delegate = self
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.messagesResultsController.performFetch()
            } catch {}
        }
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if let messages = firstSection.objects as? [TransactionMessage] {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.processMessages(messages: messages.reversed())
                }
            }
        }
    }
}