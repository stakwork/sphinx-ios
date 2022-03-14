//
//  PodcastLiveDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PodcastLiveDataSource : NSObject {
    
    var tableView: UITableView! = nil
    var chat: Chat! = nil
    var episodeId: String? = nil
    
    var messageRows: [TransactionMessageRow] = []
    
    var tableVisible: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.alpha = self.tableVisible ? 1.0 : 0.0
            })
        }
    }
    
    init(tableView: UITableView, chat: Chat) {
        super.init()
        
        self.chat = chat
        self.tableView = tableView
        
        self.tableView.registerCell(MessageReceivedTableViewCell.self)
        self.tableView.registerCell(MessageSentTableViewCell.self)
        self.tableView.registerCell(PodcastBoostReceivedTableViewCell.self)
        self.tableView.registerCell(PodcastBoostSentTableViewCell.self)
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: self.tableView.frame.height + 50))
        headerView.backgroundColor = UIColor.clear
        self.tableView.tableHeaderView = headerView
        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    func resetData() {
        tableVisible = false
        messageRows = []
        tableView.reloadData()
    }
    
    func insert(messages: [TransactionMessage]) {
        tableVisible = true
        
        var indexesToInsert = [IndexPath]()
        
        for m in messages {
            let messageRow = TransactionMessageRow(message: m)
            messageRow.isPodcastLive = true
            messageRows.append(messageRow)
            
            indexesToInsert.append(IndexPath(row: messageRows.count - 1, section: 0))
        }
        
        self.tableView.insertRows(at: indexesToInsert, with: .none)
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.tableView.scrollToBottom()
        })
    }
}

extension PodcastLiveDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let messageRow = messageRows[indexPath.row]
        let incoming = messageRow.isIncoming()
        let isPodcastBoost = messageRow.isPodcastBoost
        var height: CGFloat = 0.0
        
        if isPodcastBoost {
            height = CommonPodcastBoostTableViewCell.getRowHeight()
        } else {
            if incoming {
                height = MessageReceivedTableViewCell.getRowHeight(messageRow: messageRow)
            } else {
                height = MessageSentTableViewCell.getRowHeight(messageRow: messageRow)
            }
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageRowProtocol {
            let messageRow = messageRows[indexPath.row]
            
            cell.configureMessageRow(messageRow: messageRow, contact: nil, chat: chat)
        }
    }
}

extension PodcastLiveDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageRow = messageRows[indexPath.row]
        let isPodcastBoost = messageRow.isPodcastBoost
        let received = messageRow.isIncoming()
        
        var cell = UITableViewCell()
        
        if isPodcastBoost {
            if received {
                cell = tableView.dequeueReusableCell(withIdentifier: "PodcastBoostReceivedTableViewCell", for: indexPath) as! PodcastBoostReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "PodcastBoostSentTableViewCell", for: indexPath) as! PodcastBoostSentTableViewCell
            }
        } else {
            if received {
                cell = tableView.dequeueReusableCell(withIdentifier: "MessageReceivedTableViewCell", for: indexPath) as! MessageReceivedTableViewCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "MessageSentTableViewCell", for: indexPath) as! MessageSentTableViewCell
            }
        }
        return cell
    }
}
