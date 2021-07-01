//
//  GroupRemovedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol GroupRowDelegate: class {
    func shouldDeleteGroup()
    func shouldApproveMember(requestMessage: TransactionMessage)
    func shouldRejectMember(requestMessage: TransactionMessage)
}

class GroupRemovedTableViewCell: CommonGroupActionTableViewCell, GroupActionRowProtocol {
    
    weak var delegate: GroupRowDelegate?
    
    static let kRowHeight: CGFloat = 65.0
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        confirmButton.layer.cornerRadius = 5
    }
    
    override func getCornerRadius() -> CGFloat {
        return 8
    }
    
    
    func configureMessage(message: TransactionMessage) {
        messageLabel.text = message.getGroupMessageText()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public static func getRowHeight() -> CGFloat {
       return GroupRemovedTableViewCell.kRowHeight
    }
    
    @IBAction func confirmButtonTouched() {
        self.delegate?.shouldDeleteGroup()
    }
}
