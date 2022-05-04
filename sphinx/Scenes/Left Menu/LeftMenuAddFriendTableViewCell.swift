//
//  LeftMenuAddFriendTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class LeftMenuAddFriendTableViewCell: UITableViewCell {
    
    weak var delegate: AddFriendRowButtonDelegate?
    
    var addFriendButtonView: AddFriendRowButton!
    
    let rowHeight:CGFloat = 75

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addFriendButtonView = AddFriendRowButton(frame: CGRect(x: 0.0, y: 0.0, width: WindowsManager.getWindowWidth(), height: rowHeight))
        addFriendButtonView.delegate = self
        contentView.addSubview(addFriendButtonView)
    }
    
    func configureForAddFriend() {
        addFriendButtonView.configureForAddFriend()
    }
    
    func configureForCreateTribe() {
        addFriendButtonView.configureForCreateTribe()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension LeftMenuAddFriendTableViewCell : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        delegate?.didTouchAddFriend()
    }
    
    func didTouchCreateGroup() {
        delegate?.didTouchCreateGroup?()
    }
}
