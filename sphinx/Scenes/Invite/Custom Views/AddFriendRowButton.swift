//
//  AddFriendRowButton.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

@objc protocol AddFriendRowButtonDelegate: class {
    func didTouchAddFriend()
    @objc optional func didTouchCreateGroup()
}

class AddFriendRowButton: UIView {
    
    weak var delegate: AddFriendRowButtonDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var addFriendButtonContainer: UIView!
    @IBOutlet weak var addFriendLabel: UILabel!
    @IBOutlet weak var createGroupLabel: UILabel!
    @IBOutlet weak var createGroupContainer: UIView!
    @IBOutlet weak var createGroupLeading: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("AddFriendRowButton", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        addFriendButtonContainer.layer.cornerRadius = addFriendButtonContainer.frame.size.height / 2
        addFriendButtonContainer.clipsToBounds = true
        addFriendButtonContainer.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.GreenBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)

        createGroupContainer.layer.cornerRadius = createGroupContainer.frame.size.height / 2
        createGroupContainer.clipsToBounds = true
        createGroupContainer.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.PrimaryBlueBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
        self.accessibilityIdentifier = "addFriendRowButton"
    }
    
    func configureForAddFriend() {
        addFriendButtonContainer.isHidden = false
        createGroupContainer.isHidden = true
    }
    
    func configureForCreateTribe() {
        createGroupContainer.isHidden = false
        addFriendButtonContainer.isHidden = true
        createGroupLeading.constant = -addFriendButtonContainer.frame.width
        createGroupContainer.layoutIfNeeded()
    }
    
    func setGroupLabelTo(label: String) {
        createGroupLabel.text = label
    }
    
    func configureForGroup() {
        addFriendLabel.text = "add.people".localized
        createGroupContainer.isHidden = true
    }
    
    @IBAction func addFriendButtonTouched() {
        delegate?.didTouchAddFriend()
    }
    
    @IBAction func createGroupButtonTouched() {
        delegate?.didTouchCreateGroup?()
    }
}
