//
//  AudioReceivedTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class AudioReceivedTableViewCell: CommonAudioTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var errorContainer: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, tribeAdminId: Int?) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat)

        commonConfigurationForMessages()
        configureStatus()
        
        let bubbleSize = getBubbleSize()
        bubbleView.showIncomingAudioBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        tryLoadingAudio(messageRow: messageRow, bubbleSize: bubbleSize)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
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
    
    func tryLoadingAudio(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadAudio(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            audioLoadingFailed()
        }
    }
    
    override func audioLoadingFailed() {
        super.audioLoadingFailed()
    }
    
    override func toggleLoadingAudio(loading: Bool) {
        super.toggleLoadingAudio(loading: loading)
    }
}
