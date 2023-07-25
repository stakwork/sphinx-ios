//
//  MessageThreadView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 24/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MessageThreadView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var originalMessageBubbleView: UIView!
    @IBOutlet weak var originalMessageLabel: UILabel!
    
    @IBOutlet weak var firstReplyContainer: UIView!
    @IBOutlet weak var firstReplyBubbleView: UIView!
    @IBOutlet weak var firstReplyAvatarView: ChatAvatarView!
    
    @IBOutlet weak var secondReplyContainer: UIView!
    @IBOutlet weak var secondReplyBubbleView: UIView!
    @IBOutlet weak var secondReplyAvatarView: ChatAvatarView!
    
    @IBOutlet weak var moreRepliesContainer: UIView!
    @IBOutlet weak var moreRepliesBubbleView: UIView!
    @IBOutlet weak var moreRepliesCountView: UIView!
    @IBOutlet weak var moreRepliesCountLabel: UILabel!
    @IBOutlet weak var moreRepliesLabel: UILabel!
    
    @IBOutlet weak var messageFakeBubbleView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MessageThreadView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        setupViews()
    }
    
    func setupViews() {
        moreRepliesLabel.text = "more-replies".localized
        
        originalMessageLabel.numberOfLines = 2
        originalMessageBubbleView.layer.cornerRadius = 9
        
        firstReplyBubbleView.layer.cornerRadius = 9
        firstReplyBubbleView.layer.borderColor = UIColor.Sphinx.LightDivider.cgColor
        firstReplyBubbleView.layer.borderWidth = 1
        
        secondReplyBubbleView.layer.cornerRadius = 9
        secondReplyBubbleView.layer.borderColor = UIColor.Sphinx.LightDivider.cgColor
        secondReplyBubbleView.layer.borderWidth = 1
        
        moreRepliesBubbleView.layer.cornerRadius = 9
        moreRepliesBubbleView.layer.borderColor = UIColor.Sphinx.LightDivider.cgColor
        moreRepliesBubbleView.layer.borderWidth = 1
        
        messageFakeBubbleView.layer.cornerRadius = 9
        
        moreRepliesCountView.layer.cornerRadius = moreRepliesCountView.frame.height / 2
        
        firstReplyAvatarView.setInitialLabelSize(size: 11)
        firstReplyAvatarView.resetView()
        
        secondReplyAvatarView.setInitialLabelSize(size: 11)
        secondReplyAvatarView.resetView()
    }
    
    func configureWith(
        threadMessages: BubbleMessageLayoutState.ThreadMessages,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        ///Colors configuration for direction
        originalMessageBubbleView.backgroundColor = bubble.direction.isIncoming() ? UIColor.Sphinx.ThreadOriginalMsg : UIColor.Sphinx.SentMsgBG
        messageFakeBubbleView.backgroundColor = bubble.direction.isIncoming() ? UIColor.Sphinx.ThreadLastReply : UIColor.Sphinx.ReceivedMsgBG
        
        originalMessageLabel.textColor = bubble.direction.isIncoming() ? UIColor.Sphinx.MainBottomIcons : UIColor.Sphinx.TextMessages
        originalMessageLabel.alpha = bubble.direction.isIncoming() ? 1.0 : 0.6
        
        ///Content configuration
        originalMessageLabel.text = threadMessages.originalMessage.text
        originalMessageLabel.font = threadMessages.originalMessage.font
        
        let firstReplySenderInfo = threadMessages.firstReplySenderIndo
        firstReplyAvatarView.configureForUserWith(
            color: firstReplySenderInfo.0,
            alias: firstReplySenderInfo.1,
            picture: firstReplySenderInfo.2
        )
        
        if let secondReplySenderInfo = threadMessages.secondReplySenderInfo {
            secondReplyAvatarView.configureForUserWith(
                color: secondReplySenderInfo.0,
                alias: secondReplySenderInfo.1,
                picture: secondReplySenderInfo.2
            )
            secondReplyContainer.isHidden = false
        } else {
            secondReplyContainer.isHidden = true
        }
        
        if threadMessages.moreRepliesCount > 0 {
            moreRepliesCountLabel.text = "\(threadMessages.moreRepliesCount)"
            moreRepliesContainer.isHidden = false
        } else {
            moreRepliesContainer.isHidden = true
        }
    }

}
