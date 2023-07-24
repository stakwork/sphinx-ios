//
//  ThreadHeaderView.swift
//  sphinx
//
//  Created by James Carucci on 7/19/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

protocol ThreadHeaderViewDelegate : NSObject{
    func didTapShowMore()
    func didTapTextField()
    func didTapBackButton()
}

class ThreadHeaderView : UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var senderAvatarView: ChatAvatarView!
    @IBOutlet weak var showMoreLabel: UILabel!
    
    var delegate : ThreadHeaderViewDelegate? = nil
    var isExpanded : Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ThreadHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        message: TransactionMessage,
        delegate: ThreadHeaderViewDelegate
    ){
        self.delegate = delegate
        
        messageLabel.text = message.bubbleMessageContentString
        senderNameLabel.text = message.senderAlias
        timestampLabel.text = (message.date ?? Date()).getStringDate(format: "MMMM d yyyy 'at' h:mm a")
        
        let senderColor = ChatHelper.getSenderColorFor(message: message)
        
        senderAvatarView.configureForUserWith(
            color: senderColor,
            alias: message.senderAlias ?? "Unknow",
            picture: message.senderPic
        )
    }
    
    @IBAction func backButtonTouched() {
        delegate?.didTapBackButton()
    }
}
