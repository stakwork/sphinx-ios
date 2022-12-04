//
//  ChatMentionAutocompleteDataSource.swift
//  sphinx
//
//  Created by James Carucci on 12/4/22.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Foundation
import UIKit

class ChatMentionAutocompleteDataSource : NSObject {
    
}

extension ChatMentionAutocompleteDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel(frame: cell.frame)
        label.text = "Test"
        cell.addSubview(label)
        return cell
    }
    
    
}

