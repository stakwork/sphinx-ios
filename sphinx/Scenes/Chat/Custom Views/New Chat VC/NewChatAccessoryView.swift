//
//  NewChatAccessoryView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit


class NewChatAccessoryView: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var podcastPlayerView: PodcastSmallPlayer!
    @IBOutlet weak var messageReplyView: MessageReplyView!
    @IBOutlet weak var messageFieldView: ChatMessageTextFieldView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("NewChatAccessoryView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

//Field View
extension NewChatAccessoryView {
    func updateFieldStateFrom(_ chat: Chat?) {
        messageFieldView.updateFieldStateFrom(chat)
    }
    
    func setDelegates(
        messageFieldDelegate: ChatMessageTextFieldViewDelegate
    ) {
        messageFieldView.delegate = messageFieldDelegate
    }
    
    func populateMentionAutocomplete(
        mention: String
    ) {
        messageFieldView.populateMentionAutocomplete(mention: mention)
    }
}

//Podcast Player
extension NewChatAccessoryView {
    func configurePlayerWith(
        podcastId: String,
        delegate: PodcastPlayerVCDelegate,
        andKey playerDelegateKey: String
    ) {
        podcastPlayerView.configureWith(
            podcastId: podcastId,
            delegate: delegate,
            andKey: playerDelegateKey
        )
    }
}

//Message Reply View
extension NewChatAccessoryView {
    func configureReplyViewFor(
        message: TransactionMessage? = nil,
        podcastComment: PodcastComment? = nil,
        withDelegate delegate: MessageReplyViewDelegate
    ) {
        if let message = message {
            messageReplyView.configureForKeyboard(
                with: message,
                delegate: delegate
            )
        } else if let podcastComment = podcastComment {
            messageReplyView.configureForKeyboard(
                with: podcastComment,
                and: delegate
            )
        }
    }
}
