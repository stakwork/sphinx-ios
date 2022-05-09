//
//  ChatAvatarView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class ChatAvatarView: UIView {
    
    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileInitialContainer: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("ChatAvatarView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        profileImageView.layer.cornerRadius = self.bounds.height/2
        profileImageView.clipsToBounds = true
        
        profileInitialContainer.layer.cornerRadius = self.bounds.height/2
        profileInitialContainer.clipsToBounds = true
    }
    
    func configureFor(
        recipientAlias: String?,
        recipientPic: String?,
        tribeAdminId: Int
    ) {
        profileImageView.sd_cancelCurrentImageLoad()
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        showInitialsWith(
            alias: recipientAlias ?? "Unknown",
            color: ChatHelper.getRecipientColor(adminId: tribeAdminId, recipientAlias: recipientAlias ?? "Unknown")
        )
        
        if let recipientPic = recipientPic, let url = URL(string: recipientPic) {
            showImageWith(url: url)
        }
    }
    
    func configureFor(
        messageRow: TransactionMessageRow,
        contact: UserContact?,
        and chat: Chat?
    ) {
        profileImageView.sd_cancelCurrentImageLoad()
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        let message = messageRow.transactionMessage!
        
        if !messageRow.getConsecutiveMessages().previousMessage {
            
            showInitialsWith(
                alias: message.getMessageSenderNickname(),
                color: ChatHelper.getSenderColorFor(message: message)
            )
            
            let senderAvatarURL = message.getMessageSenderProfilePic(chat: chat, contact: contact)
            
            if let senderAvatarURL = senderAvatarURL, let url = URL(string: senderAvatarURL) {
                
                showImageWith(url: url)
            }
        }
    }
    
    func showImageWith(
        url: URL
    ) {
        profileImageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "profile_avatar"),
            options: [.lowPriority, .decodeFirstFrameOnly],
            progress: nil,
            completed: { (image, error, _, _) in
                if (error == nil) {
                    self.profileInitialContainer.isHidden = true
                    self.profileImageView.isHidden = false
                    self.profileImageView.image = image
                }
            }
        )
    }
    
    func showInitialsWith(
        alias: String,
        color: UIColor
    ) {
        profileImageView.image = nil
        
        profileInitialContainer.isHidden = false
        profileInitialContainer.backgroundColor = color
        initialsLabel.textColor = UIColor.white
        initialsLabel.text = alias.getInitialsFromName()
    }
}
