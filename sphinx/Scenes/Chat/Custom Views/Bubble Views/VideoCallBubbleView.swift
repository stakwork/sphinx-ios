//
//  VideoCallBubbleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class VideoCallBubbleView: CommonBubbleView {
    
    @IBOutlet private var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("VideoCallBubbleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func showIncomingVideoCallBubble(messageRow: TransactionMessageRow, size: CGSize) {
        showIncomingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size)
    }
    
    func showOutgoingVideoCallBubble(messageRow: TransactionMessageRow, size: CGSize) {
        showOutgoingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size)
    }
}
