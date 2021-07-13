//
//  GroupAddMemberTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupAddMemberTableViewCell: UITableViewCell {

    let rowHeight: CGFloat = 100
        
    weak var delegate: AddFriendRowButtonDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let addFriendButtonView = AddFriendRowButton(frame: CGRect(x: 0.0, y: 0.0, width: WindowsManager.getWindowWidth(), height: rowHeight))
        addFriendButtonView.delegate = self
        addFriendButtonView.configureForGroup()
        contentView.addSubview(addFriendButtonView)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension GroupAddMemberTableViewCell : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        delegate?.didTouchAddFriend()
    }
    
    func didTouchCreateGroup() {
        delegate?.didTouchCreateGroup?()
    }
}
