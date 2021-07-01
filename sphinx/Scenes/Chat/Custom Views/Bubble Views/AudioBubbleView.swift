//
//  AudioBubbleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/02/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class AudioBubbleView: CommonBubbleView {
    
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
        Bundle.main.loadNibNamed("AudioBubbleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func showIncomingAudioBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: false)
        showIncomingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble)
    }
    
    func showOutgoingAudioBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: false)
        showOutgoingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble)
    }
    
    func showIncomingClipBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: true)
        showIncomingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble)
    }
    
    func showOutgoingClipBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: true)
        showOutgoingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble)
    }
    
    func showIncomingBoostBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        showIncomingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble)
    }
    
    func showOutgoingBoostBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        showOutgoingEmptyBubble(contentView: contentView, messageRow: messageRow, size: size, consecutiveBubble: consecutiveBubble)
    }
}
