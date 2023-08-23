//
//  ThreadLastMessageHeader.swift
//  sphinx
//
//  Created by Tomas Timinskas on 24/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ThreadLastMessageHeader: UIView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("ThreadLastMessageHeader", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        chatAvatarView.setInitialLabelSize(size: 11)
        chatAvatarView.resetView()
    }
    
    func configureWith(
        threadLastReply: BubbleMessageLayoutState.ThreadLastReply
    ) {
        chatAvatarView.configureForUserWith(
            color: threadLastReply.lastReplySenderInfo.0,
            alias: threadLastReply.lastReplySenderInfo.1,
            picture: threadLastReply.lastReplySenderInfo.2
        )
        
        nameLabel.text = threadLastReply.lastReplySenderInfo.1
        dateLabel.text = threadLastReply.timestamp
    }

}
