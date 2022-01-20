//
//  ContactTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

protocol ContactCellDelegate: class {
    func shouldDeleteContact(contact: UserContact?, cell: UITableViewCell)
    func shouldBlockContact(contact: UserContact?, cell: UITableViewCell)
    func shouldGoToContact(contact: UserContact?, cell: UITableViewCell)
}

class ContactTableViewCell: SwipableCell {
    
    weak var delegate: ContactCellDelegate?
    var contact : UserContact?
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var blockedSignLabel: UILabel!
    @IBOutlet weak var bottomLine: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberOfButtons = .twoButtons
        button1.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(contact: UserContact, delegate: ContactCellDelegate, lastOnSection: Bool) {
        self.contact = contact
        self.delegate = delegate
        
        profileImageView.backgroundColor = UIColor.Sphinx.OldReceivedMsgBG
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        initialsLabel.layer.cornerRadius = initialsLabel.frame.height / 2
        initialsLabel.clipsToBounds = true
        
        bottomLine.isHidden = lastOnSection
        nameLabel.text = contact.getName()
        
        configureBlockedState(blocked: contact.isBlocked())
        loadImageFor(contact, in: profileImageView, and: initialsLabel)
    }
    
    func configureBlockedState(blocked: Bool) {
        allContentView.alpha = blocked ? 0.7 : 1.0
        blockedSignLabel.isHidden = !blocked
        isSwipeEnabled = !blocked
    }
    
    func loadImageFor(_ contact: UserContact, in imageView: UIImageView, and initialLabel: UILabel) {
        imageView.sd_cancelCurrentImageLoad()
        
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.Sphinx.Divider.resolvedCGColor(with: self)
        imageView.isHidden = true
        imageView.sd_cancelCurrentImageLoad()
        
        initialLabel.isHidden = true
        
        showInitialsFor(contact, in: initialLabel)
        
        if let imageUrl = contact.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            imageView.sd_setImage(
                with: nsUrl,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.highPriority],
                progress: nil,
                completed: { (image, error, _, _) in
                    if (error == nil) {
                        initialLabel.isHidden = true
                        imageView.isHidden = false
                        imageView.layer.borderWidth = 0
                        imageView.image = image
                    }
                }
            )
        }
    }
    
    func showInitialsFor(_ contact: UserContact, in label: UILabel) {
        let senderInitials = contact.nickname?.getInitialsFromName() ?? "name.unknown.initials".localized
        let senderColor = contact.getColor()
        
        label.isHidden = false
        label.backgroundColor = senderColor
        label.textColor = UIColor.white
        label.text = senderInitials
    }
    
    @IBAction func contactButtonTouched() {
        delegate?.shouldGoToContact(contact: contact, cell: self)
    }
    
    @IBAction func deleteButtonTouched() {
        AlertHelper.showTwoOptionsAlert(
            title: "address-boox.contact-delete.alert-title".localized,
            message: "address-boox.contact-delete.alert-message".localized,
            confirm: {
                self.delegate?.shouldDeleteContact(contact: self.contact, cell: self)
            }
        )
    }
    
    @IBAction func blockButtonTouched() {
        AlertHelper.showTwoOptionsAlert(
            title: "address-boox.contact-block.alert-title".localized,
            message: "address-boox.contact-block.alert-message".localized,
            confirm: {
                self.delegate?.shouldBlockContact(contact: self.contact, cell: self)
            }
        )
    }
    
}
