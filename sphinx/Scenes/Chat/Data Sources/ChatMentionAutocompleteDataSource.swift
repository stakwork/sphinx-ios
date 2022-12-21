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
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.Sphinx.Divider
        tableView.estimatedRowHeight = mentionCellHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        self.tableView.isHidden = (suggestions.isEmpty == true)
        self.mentionSuggestions = suggestions
        tableView.reloadData()
        if(suggestions.isEmpty == false){
            let bottom = IndexPath(
                row: 0,
                section: 0)
            tableView.scrollToRow(at: bottom, at: .bottom, animated: true)
        }
        
    }
    
}

extension ChatMentionAutocompleteDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        let labelXOffset : CGFloat = 20.0
        let label = UILabel(frame: CGRect(origin: CGPoint(x: labelXOffset, y: 0.0), size: CGSize(width: cell.frame.width - labelXOffset, height: mentionCellHeight)))
        label.text = mentionSuggestions[indexPath.row]
        label.font = UIFont(name: "Roboto", size: label.font.pointSize)
        label.textColor = UIColor.Sphinx.SecondaryText
        
        cell.addSubview(label)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        cell.backgroundColor = UIColor.Sphinx.HeaderBG
        cell.selectionStyle = .none
        
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
