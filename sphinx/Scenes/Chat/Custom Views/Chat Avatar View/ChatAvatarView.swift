//
//  ChatAvatarView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

protocol ChatAvatarViewDelegate: class {
    func didTapAvatarView()
}

class ChatAvatarView: UIView {
    
    weak var delegate: ChatAvatarViewDelegate?
    
    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileInitialContainer: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    
    var imageUrl: String? = nil
    
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
    
    func resetView() {
        profileImageView.isHidden = false
        profileImageView.image = UIImage(named: "profile_avatar")
        
        profileInitialContainer.isHidden = true
    }
    
    func setInitialLabelSize(size: Double) {
        initialsLabel.font = UIFont(name: "Montserrat-Regular", size: size)!
    }
    
    func configureForSenderWith(
        message: TransactionMessage
    ) {
        configureForUserWith(
            color: ChatHelper.getSenderColorFor(message: message),
            alias: message.senderAlias,
            picture: message.senderPic
        )
    }
    
    func configureForRecipientWith(
        message: TransactionMessage
    ) {
        configureForUserWith(
            color: ChatHelper.getRecipientColorFor(message: message),
            alias: message.recipientAlias,
            picture: message.recipientPic
        )
    }
    
    func configureForUserWith(
        color: UIColor,
        alias: String?,
        picture: String?,
        image: UIImage? = nil,
        and delegate: ChatAvatarViewDelegate? = nil
    ) {
        self.delegate = delegate
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        showInitialsWith(
            alias: alias ?? "Unknown",
            color: color
        )
        
        if let image = image {
            profileInitialContainer.isHidden = true
            profileImageView.isHidden = false
            profileImageView.image = image
        } else if let picture = picture, let url = URL(string: picture) {
            showImageWith(url: url)
        }
    }
    
    func showImageWith(
        url: URL
    ) {
        self.profileInitialContainer.isHidden = true
        self.profileImageView.isHidden = false
        
        if let imageUrl = imageUrl, imageUrl == url.absoluteString {
            return
        }
        
        let transformer = SDImageResizingTransformer(
            size: CGSize(width: bounds.size.width * 3, height: bounds.size.height * 3),
            scaleMode: .aspectFill
        )
        
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "profile_avatar"),
            options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .progressiveLoad],
            context: [.imageTransformer: transformer],
            progress: nil,
            completed: { (image, error, _, _) in
                if (error == nil) {
                    self.imageUrl = url.absoluteString
                    self.profileInitialContainer.isHidden = true
                    self.profileImageView.isHidden = false
                    self.profileImageView.image = image
                } else {
                    self.profileInitialContainer.isHidden = false
                    self.profileImageView.isHidden = true
                }
            }
        )
    }
    
    func showInitialsWith(
        alias: String,
        color: UIColor
    ) {
        profileInitialContainer.isHidden = false
        profileInitialContainer.backgroundColor = color
        initialsLabel.textColor = UIColor.white
        initialsLabel.text = alias.getInitialsFromName()
    }
    
    @IBAction func avatarViewButtonTouched() {
        if profileImageView.isHidden && profileInitialContainer.isHidden {
            return
        }
        delegate?.didTapAvatarView()
    }
}
