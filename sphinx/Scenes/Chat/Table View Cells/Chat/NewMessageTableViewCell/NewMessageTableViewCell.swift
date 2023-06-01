//
//  NewMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import Foundation

extension NewMessageTableViewCell {
    public enum MessageDirection {
        case Incoming
        case Outgoing
    }
    
    public enum GroupingState {
        case Isolated
        case First
        case Middle
        case Last
    }
}

class NewMessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bubbleOnlyText: UIView!
    @IBOutlet weak var bubbleAllView: UIView!
    @IBOutlet weak var receivedArrow: UIView!
    @IBOutlet weak var sentArrow: UIView!
    
    @IBOutlet weak var chatAvatarContainerView: UIView!
    @IBOutlet weak var sentMessageMargingView: UIView!
    @IBOutlet weak var receivedMessageMarginView: UIView!
    @IBOutlet weak var statusHeaderView: StatusHeaderView!
    
    ///First Container
    @IBOutlet weak var messageReplyView: NewMessageReplyView!
    
    ///Second Container
    @IBOutlet weak var sentPaidDetailsView: SentPaidDetails!
    @IBOutlet weak var paidTextMessageView: UIView!
    @IBOutlet weak var directPaymentView: DirectPaymentView!
    @IBOutlet weak var mediaContentView: MediaMessageView!
    
    @IBOutlet weak var textMessageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bubbleOnlyText.layer.cornerRadius = 8.0
        bubbleAllView.layer.cornerRadius = 8.0
        
        receivedArrow.drawReceivedBubbleArrow(color: UIColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: UIColor.Sphinx.SentMsgBG)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureFor(
        direction: MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        chatAvatarContainerView.isHidden = outgoing
        sentMessageMargingView.isHidden = !outgoing
        receivedMessageMarginView.isHidden = outgoing
        
        receivedArrow.isHidden = outgoing
        sentArrow.isHidden = !outgoing
        
        messageLabelLeadingConstraint.priority = UILayoutPriority(outgoing ? 1 : 1000)
        messageLabelTrailingConstraint.priority = UILayoutPriority(outgoing ? 1000 : 1)
        
        let bubbleColor = outgoing ? UIColor.Sphinx.SentMsgBG : UIColor.Sphinx.ReceivedMsgBG
        bubbleOnlyText.backgroundColor = bubbleColor
        bubbleAllView.backgroundColor = bubbleColor
        
        statusHeaderView.configureFor(direction: direction)
    }
    
    func configureFor(groupingState: GroupingState) {
        switch (groupingState) {
        case .Isolated:
            break
        case .First:
            break
        case .Middle:
            break
        case .Last:
            break
        }
    }
    
    func configureWith(
        index: Int,
        message: String
    ) {
        configureFor(direction: (index % 2 == 0) ? .Outgoing : .Incoming)
        
//        let array: [GroupingState] = [.Isolated, .First, .Middle, .Last]
//        configureFor(groupingState: array[index % 4])
        
        let moreThanText = (index % 3 == 0)

        mediaContentView.isHidden = !moreThanText
//        messageReplyView.isHidden = !moreThanText
        
        messageReplyView.isHidden = true
        sentPaidDetailsView.isHidden = true
        paidTextMessageView.isHidden = true
        directPaymentView.isHidden = true
        
//        textMessageView.isHidden = moreThanText
        
//        directPaymentView.isHidden = !moreThanText
        
        messageLabel.text = message
        
        bubbleOnlyText.isHidden = moreThanText
        bubbleAllView.isHidden = !moreThanText
    }
    
}
