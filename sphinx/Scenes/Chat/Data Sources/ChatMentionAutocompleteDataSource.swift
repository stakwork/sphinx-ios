//
//  ChatMentionAutocompleteDataSource.swift
//  sphinx
//
//  Created by James Carucci on 12/4/22.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Foundation
import UIKit


protocol ChatMentionAutocompleteDelegate{
    func processAutocomplete(text:String)
}

class ChatMentionAutocompleteDataSource : NSObject {
    var mentionSuggestions : [String] = [String]()
    var tableView : UITableView!
    var delegate: ChatMentionAutocompleteDelegate!
    let mentionCellHeight :CGFloat = 50.0
    
    init(tableView:UITableView,delegate:ChatMentionAutocompleteDelegate){
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        tableView.backgroundColor = UIColor.Sphinx.Body
        tableView.separatorColor = UIColor.Sphinx.Divider
        tableView.estimatedRowHeight = mentionCellHeight
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        self.tableView.isHidden = (suggestions.isEmpty == true)
        self.mentionSuggestions = suggestions
        //updateTableContentInset()
        tableView.reloadData()
    }
    
    func updateTableContentInset() {
        let numRows = self.tableView.numberOfRows(inSection: 0)
        var contentInsetTop = self.tableView.bounds.size.height
        for i in 0..<numRows {
            let rowRect = self.tableView.rectForRow(at: IndexPath(item: i, section: 0))
            contentInsetTop -= rowRect.size.height
            if contentInsetTop <= 0 {
                contentInsetTop = 0
                break
            }
        }
        self.tableView.contentInset = UIEdgeInsets(top: contentInsetTop,left: 0,bottom: 0,right: 0)
    }
}

extension ChatMentionAutocompleteDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let labelXOffset : CGFloat = 20.0
        let label = UILabel(frame: CGRect(origin: CGPoint(x: labelXOffset, y: 0.0), size: CGSize(width: cell.frame.width - labelXOffset, height: cell.frame.height)))
        label.text = mentionSuggestions[indexPath.row]
        label.font = UIFont(name: "Roboto", size: label.font.pointSize)
        cell.addSubview(label)
        return cell
    }
    
}

extension ChatMentionAutocompleteDataSource : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.processAutocomplete(text: mentionSuggestions[indexPath.row])
        self.tableView.isHidden = true
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return mentionCellHeight
    }
}
