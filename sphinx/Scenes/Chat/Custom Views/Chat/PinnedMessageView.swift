//
//  PinnedMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol PinnedMessageViewDelegate: class {
    func didTapPinnedMessageButtonFor(messageId: Int)
}

class PinnedMessageView: UIView {
    
    weak var delegate: PinnedMessageViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var pinnedMessageLabel: UILabel!
    
    var messageId: Int? = nil
    var completion: (() -> ())? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("PinnedMessageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.isHidden = true
    }
    
    func configureWith(
        chatId: Int,
        and delegate: PinnedMessageViewDelegate,
        completion: (() ->())? = nil
    ) {
        self.completion = completion
        
        if let chat = Chat.getChatWith(id: chatId) {
            if let pinnedMessageUUID = chat.pinnedMessageUUID, !pinnedMessageUUID.isEmptyPinnedMessage {
                if let message = TransactionMessage.getMessageWith(
                    uuid: pinnedMessageUUID
                ) {
                    setMessageAndShowView(message: message, delegate: delegate)
                } else {
                    fetchMessage(pinnedMessageUUID: pinnedMessageUUID, delegate: delegate)
                }
            } else {
                hideView()
            }
        }
    }
    
    func fetchMessage(
        pinnedMessageUUID: String,
        delegate: PinnedMessageViewDelegate
    ) {
        API.sharedInstance.getMessageBy(
            messageUUID: pinnedMessageUUID,
            callback: { messageJSON in
                if let message = TransactionMessage.insertMessage(
                    m: messageJSON,
                    existingMessage: TransactionMessage.getMessageWith(id: messageJSON["id"].intValue)
                ).0 {
                    self.setMessageAndShowView(message: message, delegate: delegate)
                } else {
                    self.hideView()
                }
            } , errorCallback: {
                self.hideView()
            }
        )
    }
    
    func setMessageAndShowView(
        message: TransactionMessage,
        delegate: PinnedMessageViewDelegate
    ) {
        self.delegate = delegate
        self.messageId = message.id
        
        pinnedMessageLabel.text = message.bubbleMessageContentString ?? ""
        
        self.isHidden = false
        
        completion?()
    }
    
    func hideView() {
        self.isHidden = true
    }
    
    @IBAction func pinnedMessageButtonTapped() {
        if let messageId = self.messageId {
            self.delegate?.didTapPinnedMessageButtonFor(messageId: messageId)
        }
    }
}
