//
//  NewChatTableDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewChatTableDataSource : NSObject {
    
    var tableView : UITableView!
    
    var messages = [
        "This is a short message",
        "This is a larger message to see how it fits in a resizable cell",
        "test",
        "This is a larger message to see how it fits in a resizable cell and now what do you think",
        "Let's test now",
        "This is a larger message to see how it fits in a resizable cell and now what do you think and then it seems it's working well, right?",
        "This is a short message",
        "This is a larger message to see how it fits in a resizable cell",
        "test",
        "This is a larger message to see how it fits in a resizable cell and now what do you think",
        "Let's test now",
        "This is a larger message to see how it fits in a resizable cell and now what do you think and then it seems it's working well, right?",
        "This is a short message",
        "This is a larger message to see how it fits in a resizable cell",
        "test",
        "This is a larger message to see how it fits in a resizable cell and now what do you think",
        "Let's test now",
        "This is a larger message to see how it fits in a resizable cell and now what do you think and then it seems it's working well, right?",
        "This is the end",
        "THE END",
        "This is a short message",
        "This is a larger message to see how it fits in a resizable cell",
        "test",
        "This is a larger message to see how it fits in a resizable cell and now what do you think",
        "Let's test now",
        "This is a larger message to see how it fits in a resizable cell and now what do you think and then it seems it's working well, right?",
        "This is a short message",
        "This is a larger message to see how it fits in a resizable cell",
        "test",
        "This is a larger message to see how it fits in a resizable cell and now what do you think",
        "Let's test now",
        "This is a larger message to see how it fits in a resizable cell and now what do you think and then it seems it's working well, right?",
        "This is a short message",
        "This is a larger message to see how it fits in a resizable cell",
        "test",
        "This is a larger message to see how it fits in a resizable cell and now what do you think",
        "Let's test now",
        "This is a larger message to see how it fits in a resizable cell and now what do you think and then it seems it's working well, right?",
        "This is the end",
        "THE END"
    ]
    
    init(
        tableView: UITableView
    ) {
        super.init()    
        self.tableView = tableView
        
        registerCells()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 300
        self.tableView.contentInset = UIEdgeInsets(top: Constants.kMargin, left: 0, bottom: Constants.kMargin, right: 0)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    func registerCells() {
        tableView.registerCell(NewMessageTableViewCell.self)
    }
}

extension NewChatTableDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 300.0
//    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if let cell = cell as? NewMessageTableViewCell {
//            cell.configureWith(index: indexPath.row, message: messages[indexPath.row])
//        }
    }

//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
}

extension NewChatTableDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewMessageTableViewCell", for: indexPath) as! NewMessageTableViewCell
        cell.configureWith(index: indexPath.row, message: messages[indexPath.row])
        return cell
    }
}
