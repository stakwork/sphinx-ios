//
//  ThreadsListDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

protocol ThreadsListDataSourceDelegate : class {
    ///Threads
    func didSelectThreadWith(uuid: String)
    
    ///Attachments
    func shouldGoToAttachmentViewFor(messageId: Int, isPdf: Bool)
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data)
    
    ///File download
    func shouldOpenActivityVCFor(url: URL)
}

class ThreadsListDataSource : NSObject {
    
    ///View references
    var tableView : UITableView!
    var noResultsFoundLabel : UILabel!
    var shimmeringView: ShimmeringList!
    
    ///Objects
    var chat: Chat?
    var owner: UserContact? = nil
    
    ///Delegate
    weak var delegate: ThreadsListDataSourceDelegate?
    
    ///Data source & Snapshot
    var threadsResultsController: NSFetchedResultsController<TransactionMessage>!
    
    var currentDataSnapshot: DataSourceSnapshot!
    var dataSource: DataSource!
    
    let audioPlayerHelper = AudioPlayerHelper()
    
    typealias DataSource = UITableViewDiffableDataSource<CollectionViewSection, ThreadTableCellState>
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<CollectionViewSection, ThreadTableCellState>
    
    enum CollectionViewSection: Int, CaseIterable {
        case threads
    }
    
    var threadTableCellStateArray: [ThreadTableCellState] = []
    var mediaCached: [Int: MessageTableCellState.MediaData] = [:]
    
    init(
        chat: Chat?,
        tableView : UITableView,
        noResultsFoundLabel : UILabel,
        shimmeringView: ShimmeringList,
        delegate: ThreadsListDataSourceDelegate?
    ) {
        super.init()
        
        self.chat = chat
        self.owner = UserContact.getOwner()
        
        self.delegate = delegate
        self.tableView = tableView
        self.shimmeringView = shimmeringView
        self.noResultsFoundLabel = noResultsFoundLabel
        
        configureTableView()
        configureDataSource()
    }
    
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 128.0
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset.bottom = getWindowInsets().bottom
        
        tableView.registerCell(ThreadListTableViewCell.self)
    }
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: self.tableView,
            cellProvider: makeCellProvider(for: self.tableView)
        )

        return dataSource
    }
    
    func configureDataSource() {
        dataSource = makeDataSource()

        configureResultsController()
    }
    
    func makeSnapshotForCurrentState() -> DataSourceSnapshot {
        var snapshot = DataSourceSnapshot()

        snapshot.appendSections([CollectionViewSection.threads])

        snapshot.appendItems(
            threadTableCellStateArray,
            toSection: .threads
        )

        return snapshot
    }
    
    func updateSnapshot() {
        let snapshot = makeSnapshotForCurrentState()

        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: false)
            self.tableView.alpha = 1.0
            self.toggleElementsVisibility()
        }
    }
    
    func toggleElementsVisibility() {
        noResultsFoundLabel.isHidden = !threadTableCellStateArray.isEmpty
        tableView.isHidden = threadTableCellStateArray.isEmpty
        shimmeringView.isHidden = threadTableCellStateArray.isEmpty
    }
    
    func makeCellProvider(
        for tableView: UITableView
    ) -> DataSource.CellProvider {
        { [weak self] (tableView, indexPath, dataSourceItem) -> UITableViewCell? in
            guard let self else {
                return nil
            }
            
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "ThreadListTableViewCell",
                for: indexPath
            ) as! ThreadListTableViewCell
            
            let mediaData = (dataSourceItem.messageId != nil) ? self.mediaCached[dataSourceItem.messageId!] : nil
            
            cell.configureWith(
                threadCellState: dataSourceItem,
                mediaData: mediaData,
                delegate: self,
                indexPath: indexPath
            )
            
            return cell
        }
    }
    
    func processThreadMessages(
        _ messages: [TransactionMessage]
    ) {
        guard let chat = chat, let owner = owner else {
            return
        }
        
        let threadUUIDs = messages.map({ $0.threadUUID ?? "" }).filter({ $0.isNotEmpty })
        let uniqueThreadUUIDs = Array(Set(threadUUIDs))
        
        let originalMessages = TransactionMessage.getOriginalMessagesFor(uniqueThreadUUIDs, on: chat)
        
        let threadMessagesMap = getThreadMessagesFrom(
            originalMessages: originalMessages,
            threadMessages: messages
        )
        
        threadTableCellStateArray = []
        
        for originalMesage in originalMessages {
            if let uuid = originalMesage.uuid, let threadMessageMap = threadMessagesMap[uuid] {
                
                if threadMessageMap.1.count > 1 {
                    threadTableCellStateArray.append(
                        ThreadTableCellState(
                            originalMessage: threadMessageMap.0,
                            threadMessages: threadMessageMap.1,
                            owner: owner
                        )
                    )
                }
            }
        }
        
        threadTableCellStateArray = threadTableCellStateArray.sorted(by: {
            return $0.threadMessages.last?.date ?? Date() > $1.threadMessages.last?.date ?? Date()
        })
        
        updateSnapshot()
    }
    
    func getThreadMessagesFrom(
        originalMessages: [TransactionMessage],
        threadMessages: [TransactionMessage]
    ) -> [String: (TransactionMessage, [TransactionMessage])] {
        
        var threadMessagesMap: [String: (TransactionMessage, [TransactionMessage])] = [:]
        
        for originalMessage in originalMessages {
            if let uuid = originalMessage.uuid {
                threadMessagesMap[uuid] = (originalMessage, [])
            }
        }
        
        for threadMessage in threadMessages {
            if let threadUUID = threadMessage.threadUUID {
                threadMessagesMap[threadUUID]?.1.append(threadMessage)
            }
        }
        
        return threadMessagesMap
    }
}

extension ThreadsListDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if threadTableCellStateArray.count > indexPath.row {
            if let messageUUID = threadTableCellStateArray[indexPath.row].originalMessage?.uuid {
                delegate?.didSelectThreadWith(uuid: messageUUID)
            }
        }
    }
}

extension ThreadsListDataSource : NSFetchedResultsControllerDelegate {
    
    func startListeningToResultsController() {
        threadsResultsController?.delegate = self
    }
    
    func stopListeningToResultsController() {
        threadsResultsController?.delegate = nil
    }
    
    func configureResultsController() {
        guard let chat = chat else {
            return
        }
        
        let fetchRequest = TransactionMessage.getThreadsFetchRequestOn(chat: chat)

        threadsResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataManager.sharedManager.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        threadsResultsController.delegate = self
        
        CoreDataManager.sharedManager.persistentContainer.viewContext.perform {
            do {
                try self.threadsResultsController.performFetch()
            } catch {}
        }
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        if let resultController = controller as? NSFetchedResultsController<NSManagedObject>,
            let firstSection = resultController.sections?.first {
            
            if controller == threadsResultsController {
                if let messages = firstSection.objects as? [TransactionMessage] {
                    processThreadMessages(messages)
                }
            }
        }
    }
}
