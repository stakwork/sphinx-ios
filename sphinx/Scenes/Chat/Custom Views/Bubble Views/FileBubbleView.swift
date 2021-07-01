//
//  FileBubbleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class FileBubbleView: CommonBubbleView {
    
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
        Bundle.main.loadNibNamed("FileBubbleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func showIncomingFileBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let isPaidAttachment = messageRow.isPaidAttachment
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent()
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: attachmentHasText || isPaidAttachment)
        showIncomingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubbles)
    }
    
    func showOutgoingFileBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent()
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: attachmentHasText)
        showOutgoingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubbles)
    }
}
