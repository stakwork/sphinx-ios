//
//  GroupActionMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupActionMessageTableViewCell: CommonGroupActionTableViewCell, GroupActionRowProtocol {
    
    weak var delegate: GroupRowDelegate?
    
    static let kGroupLeaveRowHeight: CGFloat = 40.0
    
    @IBOutlet weak var groupLeaveLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessage(message: TransactionMessage) {
        let groupMessageText = message.getGroupMessageText()
        groupLeaveLabel.text = groupMessageText
    }
    
    public static func getRowHeight() -> CGFloat {
       return GroupActionMessageTableViewCell.kGroupLeaveRowHeight
    }   
}
