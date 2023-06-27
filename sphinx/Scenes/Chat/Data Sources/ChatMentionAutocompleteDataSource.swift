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
    var mentionSuggestions : [MentionOrMacroItem] = [MentionOrMacroItem]()
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
        tableView.register(UINib(nibName: "ChatMentionAutocompleteTableViewCell", bundle: nil), forCellReuseIdentifier: ChatMentionAutocompleteTableViewCell.reuseID)
    }
    
    func updateMentionSuggestions(suggestions:[String]){
        tableView.isHidden = (suggestions.isEmpty == true)
        let suggestionObjects = suggestions.compactMap({
            let result = MentionOrMacroItem(type: .mention, displayText: $0, action: nil)
            return result
        })
        mentionSuggestions = suggestionObjects
        
        tableView.reloadData()
        
        if (suggestions.isEmpty == false) {
            let bottom = IndexPath(
                row: 0,
                section: 0
            )
            tableView.scrollToRow(at: bottom, at: .bottom, animated: true)
        }
        
    }
    
}

extension ChatMentionAutocompleteDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionSuggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatMentionAutocompleteTableViewCell.reuseID,
            for: indexPath
        ) as! ChatMentionAutocompleteTableViewCell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let mentionCell = cell as? ChatMentionAutocompleteTableViewCell//,
           //let valid_vc = vc
        {
            mentionCell.configureWith(mentionOrMacro: mentionSuggestions[indexPath.item], delegate: nil)
        }
    }
    
}

extension ChatMentionAutocompleteDataSource : UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //self.delegate?.processAutocomplete(text: mentionSuggestions[indexPath.row])
        self.tableView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return mentionCellHeight
    }
}
