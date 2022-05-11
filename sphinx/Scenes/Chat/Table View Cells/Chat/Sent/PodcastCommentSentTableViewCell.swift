//
//  PodcastCommentSentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PodcastCommentSentTableViewCell: CommonPodcastCommentTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var seenSign: UILabel!
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
        configureAudioAndMessage(podcast: chat?.podcast)
        configureMessageStatus()

        if messageRow.shouldShowRightLine {
           addRightLine()
        }

        if messageRow.shouldShowLeftLine {
           addLeftLine()
        }
    }
    
    func configureAudioAndMessage(podcast: PodcastFeed?) {
        guard let messageRow = messageRow else {
           return
        }

        let bubbleSize = CGSize(width: CommonPodcastCommentTableViewCell.kAudioSentBubbleWidth, height: CommonPodcastCommentTableViewCell.kAudioBubbleHeight)
        bubbleView.showOutgoingClipBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)
        
        messageBubbleView.clearBubbleView()
        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: CommonPodcastCommentTableViewCell.kAudioSentBubbleWidth)
            addLinksOnLabel(label: label)
        }

        tryLoadingAudio(messageRow: messageRow, podcast: podcast, bubbleSize: bubbleSize)
    }

    func tryLoadingAudio(messageRow: TransactionMessageRow, podcast: PodcastFeed?, bubbleSize: CGSize) {
        if let podcastComment = messageRow.transactionMessage.podcastComment, let _ = podcastComment.url {
            loadAudio(podcastComment: podcastComment, podcast: podcast, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            audioLoadingFailed()
        }
    }

    override func audioLoadingFailed() {
        super.audioLoadingFailed()
        configureMessageStatus()
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let expired = messageRow.transactionMessage.isMediaExpired()
        configureLockSign()
        
        seenSign.text = received ? "flash_on" : ""
        seenSign.alpha = received ? 1.0 : 0.0
        errorContainer.alpha = failed || expired ? 1.0 : 0.0
        errorMessageLabel.text = expired ? "media.terms.expired".localized : "message.failed".localized
    }
}
