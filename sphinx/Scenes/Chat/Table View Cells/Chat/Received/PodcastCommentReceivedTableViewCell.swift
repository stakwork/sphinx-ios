//
//  PodcastCommentReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PodcastCommentReceivedTableViewCell: CommonPodcastCommentTableViewCell, MessageRowProtocol {
    
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
        configureStatus()
        configureAudioAndMessage(podcast: chat?.podcast)

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
        
        let bubbleSize = CGSize(width: CommonPodcastCommentTableViewCell.kAudioReceivedBubbleWidth, height: CommonPodcastCommentTableViewCell.kAudioBubbleHeight)
        bubbleView.showIncomingClipBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        messageBubbleView.clearBubbleView()
        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: CommonPodcastCommentTableViewCell.kAudioReceivedBubbleWidth)
            addLinksOnLabel(label: label)
        }
        
        tryLoadingAudio(messageRow: messageRow, podcast: podcast, bubbleSize: bubbleSize)
    }
    
    func configureStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        configureLockSign()
        
        let expired = messageRow.transactionMessage.isMediaExpired()
        errorMessageLabel.text = "media.terms.expired".localized
        errorContainer.alpha = expired ? 1.0 : 0.0
    }
    
    func tryLoadingAudio(messageRow: TransactionMessageRow, podcast: PodcastFeed?, bubbleSize: CGSize) {
        if let podcastComment = messageRow.transactionMessage.podcastComment, let _ = podcastComment.url {
            loadAudio(podcastComment: podcastComment, podcast: podcast, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            audioLoadingFailed()
        }
    }
}
