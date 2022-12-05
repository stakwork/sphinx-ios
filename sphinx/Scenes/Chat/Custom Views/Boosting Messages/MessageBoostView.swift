//
//  MessageBoostView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class MessageBoostView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var boostIconContainer: UIView!
    @IBOutlet weak var boostIcon: UIImageView!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var initialsContainer1: UIView!
    @IBOutlet weak var initialsContainer2: UIView!
    @IBOutlet weak var initialsContainer3: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("MessageBoostView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        boostIconContainer.layer.cornerRadius = 2
        leftMargin.constant = Constants.kLabelMargins
        rightMargin.constant = Constants.kLabelMargins
        layoutIfNeeded()
    }

    func configure(message: TransactionMessage) {
        configureIncoming(message)
        
        let boosted = message.reactions?.boosted ?? false
        configureBoostIcon(active: boosted || message.isOutgoing())
        
        let amount = message.reactions?.totalSats ?? 0
        amountLabel.text = amount.formattedWithSeparator
        
        let totalUsers = message.reactions?.users.count ?? 0
        countLabel.text = totalUsers > 3 ? " +\(totalUsers - 3)" : ""
        
        showCircles(message)
    }
    
    func configureBoostIcon(active: Bool) {
        boostIconContainer.backgroundColor = active ? UIColor.Sphinx.PrimaryGreen : UIColor.Sphinx.WashedOutReceivedText
        boostIcon.tintColor = active ? UIColor.white : UIColor.Sphinx.OldReceivedMsgBG
        boostIcon.tintColorDidChange()
    }
    
    func configureIncoming(_ message: TransactionMessage) {
        let incoming = message.isIncoming()
        
        unitLabel.textColor = incoming ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        countLabel.textColor = incoming ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        
        let size: CGFloat = incoming ? 11 : 16
        amountLabel.font = UIFont(name: incoming ? "Roboto-Regular" : "Roboto-Medium", size: size)!
        unitLabel.font = UIFont(name: "Roboto-Regular", size: size)!
    }
    
    func showCircles(_ message: TransactionMessage) {
        guard let reactions = message.reactions else {
            return
        }
        let incoming = message.isIncoming()
        let containers = [initialsContainer1, initialsContainer2, initialsContainer3]
        
        var i = 0
        for (name, (color, image)) in reactions.users {
            if i >= 3 { return }
            
            if let container = containers[i] {
                showInitialsFor(name, color: color, and: image, in: container, incoming: incoming)
                
            }
            
            i = i + 1
        }
    }
    
    func showInitialsFor(
        _ name: String,
        color: UIColor,
        and imageUrl: String?,
        in container: UIView, incoming: Bool
    ) {
        container.isHidden = false
        container.layer.cornerRadius = container.frame.size.height / 2
        
        let backgroundColor = incoming ? UIColor.Sphinx.OldReceivedMsgBG : UIColor.Sphinx.OldSentMsgBG
        container.backgroundColor = backgroundColor
        
        for view in container.subviews {
            if let label = view as? UILabel {
                label.text = name.getInitialsFromName()
            } else if let imageView = view as? UIImageView {
                imageView.layer.cornerRadius = imageView.frame.size.height / 2
                
                if let imageUrl = imageUrl {
                    if let url = URL(string: imageUrl) {
                        imageView.sd_setImage(
                            with: url,
                            placeholderImage: UIImage(named: "profile_avatar"),
                            options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                            progress: nil
                        )
                    }
                } else {
                    imageView.image = nil
                }
            } else {
                view.backgroundColor = color
                view.layer.cornerRadius = view.frame.size.height / 2
            }
        }
    }
    
    func addConstraintsTo(bubbleView: UIView, messageRow: TransactionMessageRow) {
        let isIncoming = messageRow.isIncoming()
        let hasLinksPreview = (messageRow.shouldShowLinkPreview() ||
                               messageRow.shouldShowTribeLinkPreview() ||
                               messageRow.shouldShowPubkeyPreview()) && messageRow.transactionMessage.linkHasPreview
        let paidReceivedItem = messageRow.shouldShowPaidAttachmentView()
        
        let leftMargin = isIncoming ? Constants.kBubbleReceivedArrowMargin : 0
        let rightMargin = isIncoming ? 0 : Constants.kBubbleSentArrowMargin
        
        let linkPreviewHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow)
        
        var bottomMargin: CGFloat = 0
        if hasLinksPreview { bottomMargin += linkPreviewHeight }
        if paidReceivedItem { bottomMargin += PaidAttachmentView.kViewHeight }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -bottomMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: leftMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: -rightMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: Constants.kReactionsViewHeight + Constants.kLabelMargins).isActive = true
    }
}
