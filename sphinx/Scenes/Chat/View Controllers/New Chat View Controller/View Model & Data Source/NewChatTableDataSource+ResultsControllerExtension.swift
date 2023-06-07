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

        let snapshot = makeSnapshotForCurrentState()

        dataSource.apply(snapshot, animatingDifferences: false)
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
            self.dataSource.apply(snapshot, animatingDifferences: false)
            
            self.tableView.scrollToRow(
                at: IndexPath(
                    item: self.messageTableCellStateArray.count - 1,
                    section: 0
                ),
                at: .bottom,
                animated: false
            )
            self.tableView.alpha = 1.0
        }
    }
    
    func makeCellProvider(
        for tableView: UITableView
    ) -> DataSource.CellProvider {
        { (tableView, indexPath, dataSourceItem) -> UITableViewCell in
            
            var mutableDataSourceItem = dataSourceItem
            
            if let _ = mutableDataSourceItem.bubble {
                let cell = tableView.dequeueReusableCell(withIdentifier: "NewMessageTableViewCell", for: indexPath) as! NewMessageTableViewCell
                cell.configureWith(messageCellState: dataSourceItem)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageNoBubbleTableViewCell", for: indexPath) as! MessageNoBubbleTableViewCell
                return cell
            }
        }
    }
}

extension NewChatTableDataSource {
    
    func configureResultsController() {
        let fetchRequest = TransactionMessage.getChatMessagesFetchRequest(for: chat, with: 100)

        messagesResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        messagesResultsController.delegate = self
        
        do {
            try messagesResultsController.performFetch()
        } catch {}
    }
    
    func processMessages(
        messages: [TransactionMessage]
    ) {
        guard let owner = UserContact.getOwner() else {
            return
        }
        
        var array: [MessageTableCellState] = []
        
        let admin = chat.getAdmin()
        let contact = chat.getConversationContact()
        
        for message in messages.reversed() {
            if message.isTextMessage() {
                array.append(
                    MessageTableCellState(
                        message: message,
                        chat: chat,
                        owner: owner,
                        contact: contact,
                        tribeAdmin: admin,
                        separatorDate: nil,
                        bubbleState: MessageTableCellState.BubbleState.Isolated
                    )
                )
            }
        }
        
        messageTableCellStateArray = array
        
        updateSnapshot()
    }
}

extension NewChatTableDataSource : NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if
            let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if let messages = firstSection.objects as? [TransactionMessage] {
                let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
                dispatchQueue.async {
                    self.processMessages(messages: messages)
                }
            }
        }
    }
}
