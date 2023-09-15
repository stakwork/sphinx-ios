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
    var owner: UserContact? = nil
    var chatContact: UserContact? = nil
    var tribeAdmin: UserContact? = nil
    
    var episodeId: String? = nil
    var messagesTableCellStates: [MessageTableCellState] = []
    
    var tableVisible: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.alpha = self.tableVisible ? 1.0 : 0.0
            })
        }
    }
    
    init(
        tableView: UITableView,
        chat: Chat
    ) {
        super.init()
        
        self.owner = UserContact.getOwner()
        self.chat = chat
        self.chatContact = chat.getConversationContact()
        self.tribeAdmin = chat.getAdmin()
        
        self.tableView = tableView
        self.tableView.registerCell(NewMessageTableViewCell.self)

        let headerView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: self.tableView.frame.width,
                height: self.tableView.frame.height + 50
            )
        )
        headerView.backgroundColor = UIColor.clear
        self.tableView.tableHeaderView = headerView

        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    func resetData() {
        tableVisible = false
        messagesTableCellStates = []
        tableView.reloadData()
    }
    
    func insert(messages: [TransactionMessage]) {
        guard let owner = owner else {
            return
        }
        
        tableVisible = true

        var indexesToInsert = [IndexPath]()

        for m in messages {
            let celState = MessageTableCellState(
                message: m,
                chat: self.chat,
                owner: owner,
                contact: self.chatContact,
                tribeAdmin: self.tribeAdmin,
                separatorDate: nil,
                bubbleState: MessageTableCellState.BubbleState.Isolated,
                contactImage: nil,
                replyingMessage: nil,
                boostMessages: [],
                purchaseMessages: [:],
                linkContact: nil,
                linkTribe: nil,
                linkWeb: nil,
                invoiceData: (false, false)
            )
            
            messagesTableCellStates.append(celState)
            indexesToInsert.append(IndexPath(row: messagesTableCellStates.count - 1, section: 0))
        }

        self.tableView.insertRows(at: indexesToInsert, with: .none)

        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.tableView.scrollToBottom()
        })
    }
}


extension PodcastLiveDataSource : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesTableCellStates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCellState = messagesTableCellStates[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NewMessageTableViewCell",
            for: indexPath
        ) as! NewMessageTableViewCell
        
        cell.configureWith(
            messageCellState: tableCellState,
            mediaData: nil,
            threadOriginalMsgMediaData: nil,
            tribeData: nil,
            linkData: nil,
            botWebViewData: nil,
            uploadProgressData: nil,
            delegate: nil,
            searchingTerm: nil,
            indexPath: indexPath
        )
        
        return cell
    }
}
