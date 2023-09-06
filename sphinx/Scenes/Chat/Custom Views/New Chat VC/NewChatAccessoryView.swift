//
//  NewChatAccessoryView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit


class NewChatAccessoryView: UIView {
    
    weak var searchDelegate: ChatSearchResultsBarDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var normalModeStackView: UIStackView!
    @IBOutlet weak var podcastPlayerView: PodcastSmallPlayer!
    @IBOutlet weak var messageReplyView: MessageReplyView!
    @IBOutlet weak var messageFieldView: ChatMessageTextFieldView!
    @IBOutlet weak var chatSearchView: ChatSearchResultsBar!
    
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
        messageFieldDelegate: ChatMessageTextFieldViewDelegate,
        searchDelegate: ChatSearchResultsBarDelegate? = nil
    ) {
        messageFieldView.delegate = messageFieldDelegate
        
        self.searchDelegate = searchDelegate
    }
    
    func populateMentionAutocomplete(
        mention: String
    ) {
        messageFieldView.populateMentionAutocomplete(mention: mention)
    }
    
    func setupForAttachments(
        with text: String?,
        andDelegate messageFieldDelegate: ChatMessageTextFieldViewDelegate
    ) {
        messageFieldView.delegate = messageFieldDelegate
        messageFieldView.setupForAttachments(with: text)
    }
    
    func setupForThreads(
        with delegate: ChatMessageTextFieldViewDelegate
    ) {
        messageFieldView.delegate = delegate
    }
    
    func getMessage() -> String {
        messageFieldView.getMessage()
    }
    
    func clearMessage() {
        messageFieldView.clearMessage()
    }
}

//Audio Recorder
extension NewChatAccessoryView {
    func toggleAudioRecording(show: Bool) {
        messageFieldView.toggleAudioRecording(show: show)
    }
    
    func updateRecordingAudio(minutes: String, seconds: String) {
        messageFieldView.updateRecordingAudio(minutes: minutes, seconds: seconds)
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
    
    func resetReplyView() {
        messageReplyView.resetAndHideView()
    }
}

//Search Mode
extension NewChatAccessoryView {
    func configureSearchWith(
        active: Bool,
        loading: Bool,
        matchesCount: Int? = nil,
        matchIndex: Int = 0
    ) {
        normalModeStackView.isHidden = active
        chatSearchView.isHidden = !active
        
        chatSearchView.configureWith(
            matchesCount: matchesCount,
            matchIndex: matchIndex,
            loading: loading,
            delegate: self
        )
    }
    
    func shouldToggleSearchLoadingWheel(active: Bool) {
        chatSearchView.toggleLoadingWheel(active: active)
    }
}

extension NewChatAccessoryView : ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton) {
        searchDelegate?.didTapNavigateArrowButton(button: button)
    }
}
