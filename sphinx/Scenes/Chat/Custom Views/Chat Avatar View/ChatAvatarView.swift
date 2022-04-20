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
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height/2
        profileImageView.clipsToBounds = true
        
        profileInitialContainer.layer.cornerRadius = profileInitialContainer.frame.size.height/2
        profileInitialContainer.clipsToBounds = true
    }
    
    func configureFor(messageRow: TransactionMessageRow, contact: UserContact?, and chat: Chat?) {
        
        profileImageView.sd_cancelCurrentImageLoad()
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        let message = messageRow.transactionMessage!
        
        if !messageRow.getConsecutiveMessages().previousMessage {
            showInitialsFor(message: message)
            
            let senderAvatarURL = message.getMessageSenderProfilePic(chat: chat, contact: contact)
            
            if let senderAvatarURL = senderAvatarURL, let nsUrl = URL(string: senderAvatarURL) {
                
                profileImageView.sd_setImage(
                    with: nsUrl,
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
        }
    }
    
    func showInitialsFor(message: TransactionMessage) {
        self.profileImageView.image = nil
        
        let senderNickname = message.getMessageSenderNickname()
        let senderColor = ChatHelper.getSenderColorFor(message: message)
        
        profileInitialContainer.isHidden = false
        profileInitialContainer.backgroundColor = senderColor
        initialsLabel.textColor = UIColor.white
        initialsLabel.text = senderNickname.getInitialsFromName()
    }
}
