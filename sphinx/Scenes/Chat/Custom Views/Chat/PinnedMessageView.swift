//
//  PinnedMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

protocol PinnedMessageViewDelegate: class {
    func didTapButtonFor(messageObjectId: NSManagedObjectID)
}

class PinnedMessageView: UIView {
    
    weak var delegate: PinnedMessageViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var pinnedMessageLabel: UILabel!
    
    var messageObjectId: NSManagedObjectID? = nil
    
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
    }
    
    func configureWith(
        chatObjectId: NSManagedObjectID?,
        and delegate: PinnedMessageViewDelegate
    ) {
        if let chatObjectId = chatObjectId {
            
            if let chat: Chat? = CoreDataManager.sharedManager.getObjectWith(
                objectId: chatObjectId
            ) {
                if let pinnedMessageUUID = chat?.pinnedMessageUUID, !pinnedMessageUUID.isEmpty {
                    
                    if let message = TransactionMessage.getMessageWith(
                        uuid: pinnedMessageUUID
                    ) {
                        self.delegate = delegate
                        self.messageObjectId = message.objectID
                        
                        pinnedMessageLabel.text = message.messageContent
                        self.isHidden = false
                    }
                } else {
                    self.isHidden = true
                }
            }
        }
    }
    
    @IBAction func pinnedMessageButtonTapped() {
        if let messageObjectId = self.messageObjectId {
            self.delegate?.didTapButtonFor(messageObjectId: messageObjectId)
        }
    }
}
