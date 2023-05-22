//
//  PinnedMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

class PinnedMessageView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var pinnedMessageLabel: UILabel!
    
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
    
    func configureWith(chatObjectId: NSManagedObjectID?) {
        if let chatObjectId = chatObjectId {
            if let chat: Chat? = CoreDataManager.sharedManager.getObjectWith(objectId: chatObjectId) {
                if let pin = chat?.pin, !pin.isEmpty {
                    if let message = TransactionMessage.getMessageWith(uuid: pin) {
                        pinnedMessageLabel.text = message.messageContent
                    }
                }
            }
        }
    }
}
