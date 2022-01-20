//
//  GroupContactCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol GroupContactCellDelegate: class {
    func didDeleteContact(contact: UserContact, cell: UICollectionViewCell)
}

class GroupContactCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: GroupContactCellDelegate?
    
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitialsLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var closeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    var groupContact : GroupAddedContactsDataSource.GroupContact!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contactImageView.contentMode = .scaleAspectFill
        contactImageView.layer.cornerRadius = contactImageView.frame.size.height / 2
        
        contactInitialsLabel.layer.cornerRadius = contactInitialsLabel.frame.size.height / 2
        contactInitialsLabel.clipsToBounds = true
        
        closeLabel.layer.cornerRadius = closeLabel.frame.size.height / 2
        closeLabel.clipsToBounds = true
    }

    @IBAction func closeButtonTouched() {
        delegate?.didDeleteContact(contact: groupContact.contact, cell: self)
    }
    
    func configureFor(groupContact: GroupAddedContactsDataSource.GroupContact) {
        self.groupContact = groupContact
        
        guard let contact = groupContact.contact else {
            return
        }
        
        closeLabel.isHidden = groupContact.existing
        closeButton.isHidden = groupContact.existing
        
        nameLabel.text = (contact.nickname ?? "").getFirstNameStyleString()
        
        showInitials(contact: contact)
        
        contactImageView.sd_cancelCurrentImageLoad()
        
        if let imageUrl = contact.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            contactImageView.sd_setImage(
                with: nsUrl,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.highPriority],
                progress: nil,
                completed: { (image, error, _, _) in
                    if (error == nil) {
                        self.contactInitialsLabel.isHidden = true
                        self.contactImageView.isHidden = false
                        self.contactImageView.image = image
                    }
                }
            )
        }
    }
    
    func showInitials(contact: UserContact) {
        let senderNickname = contact.nickname ?? "name.unknown".localized
        let senderColor = contact.getColor()
        
        contactInitialsLabel.isHidden = false
        contactImageView.isHidden = true
        contactInitialsLabel.backgroundColor = senderColor
        contactInitialsLabel.textColor = UIColor.white
        contactInitialsLabel.text = senderNickname.getInitialsFromName()
    }
}
