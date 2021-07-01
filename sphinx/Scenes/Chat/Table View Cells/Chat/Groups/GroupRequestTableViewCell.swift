//
//  GroupRequestTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/07/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class GroupRequestTableViewCell: CommonGroupActionTableViewCell, GroupActionRowProtocol {
    
    weak var delegate: GroupRowDelegate?
    
    @IBOutlet weak var groupApprovalLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    static let kRowHeight: CGFloat = 65.0
    
    public enum Button: Int {
        case Approve
        case Reject
    }
    
    var contact: UserContact? = nil
    var message: TransactionMessage? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        
        acceptButton.layer.cornerRadius = acceptButton.frame.size.height / 2
        declineButton.layer.cornerRadius = declineButton.frame.size.height / 2
    }
    
    override func getCornerRadius() -> CGFloat {
        return 8
    }
    
    func configureMessage(message: TransactionMessage) {
        let senderId = message.senderId
        self.contact = UserContact.getContactWith(id: senderId)
        self.message = message
        
        let activeMember = message.chat?.isActiveMember(id: senderId) ?? true
        
        let declined = message.isDeclinedRequest()
        let accepted = message.isApprovedRequest()
        let pending = !declined && !accepted
        
        setLabel(message: message, declined: declined, accepted: accepted)
        
        acceptButton.isEnabled = !activeMember && pending
        declineButton.isEnabled = !activeMember && pending

        acceptButton.alpha = declined ? 0.5 : 1.0
        declineButton.alpha = accepted ? 0.5 : 1.0
    }
    
    func setLabel(message: TransactionMessage, declined: Bool, accepted: Bool) {
        groupApprovalLabel.text = message.getGroupMessageText()
        let senderNickname = message.getMessageSenderNickname()
        
        if accepted {
            groupApprovalLabel.text = String(format: "admin.request.approved".localized, senderNickname)
        } else if declined {
            groupApprovalLabel.text = String(format: "admin.request.rejected".localized, senderNickname)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public static func getRowHeight() -> CGFloat {
       return GroupRequestTableViewCell.kRowHeight
    }
    
    @IBAction func buttonTouched(_ sender: UIButton) {
        guard let message = self.message else {
            return
        }
        
        NewMessageBubbleHelper().showLoadingWheel()
        
        switch (sender.tag) {
        case Button.Approve.rawValue:
            delegate?.shouldApproveMember(requestMessage: message)
            break
        case Button.Reject.rawValue:
            delegate?.shouldRejectMember(requestMessage: message)
            break
        default:
            break
        }
    }
}

