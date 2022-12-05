//
//  GroupContactTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol GroupMemberCellDelegate: class {
    func didKickContact(contact: GroupAllContactsDataSource.GroupContact, cell: UITableViewCell)
    func shouldApproveMember(_ contact: GroupAllContactsDataSource.GroupContact, requestMessage: TransactionMessage)
    func shouldRejectMember(_ contact: GroupAllContactsDataSource.GroupContact, requestMessage: TransactionMessage)
}

class GroupContactTableViewCell: SwipableCell {
    
    weak var delegate: GroupMemberCellDelegate?
    
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var contactInitialsLabel: UILabel!
    @IBOutlet weak var checkboxLabel: UILabel!
    @IBOutlet weak var letterLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var approveButtonsContainer: UIView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    var contact: GroupAllContactsDataSource.GroupContact! = nil
    var chat: Chat? = nil
    var pendingContact = false
    
    public enum Button: Int {
        case Approve
        case Reject
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contactImageView.contentMode = .scaleAspectFill
        contactImageView.backgroundColor = UIColor.Sphinx.OldReceivedMsgBG
        contactImageView.layer.cornerRadius = contactImageView.frame.size.height / 2
        contactImageView.clipsToBounds = true
        
        contactInitialsLabel.layer.cornerRadius = contactInitialsLabel.frame.size.height / 2
        contactInitialsLabel.clipsToBounds = true
        
        declineButton.layer.cornerRadius = declineButton.frame.size.height / 2
        acceptButton.layer.cornerRadius = acceptButton.frame.size.height / 2
        
        approveButtonsContainer.isHidden = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureFor(groupContact: GroupAllContactsDataSource.GroupContact,
                      chat: Chat? = nil,
                      delegate: GroupMemberCellDelegate? = nil,
                      isPending: Bool = false,
                      isLastCell: Bool = false) {
        
        isUserInteractionEnabled = true
        
        self.chat = chat
        self.contact = groupContact
        self.delegate = delegate
        self.pendingContact = isPending
        
        let showDelete = shouldAllowDelete()
        configureDeleteButton(showDelete: showDelete)
        
        separatorLine.isHidden = isLastCell
        approveButtonsContainer.isHidden = !isPending
        
        contactNameLabel.text = contact.getName()
        configureInitial(nickname: contact.getName(), firstOnLetter: groupContact.firstOnLetter)
        configureCheckbox(selected: groupContact.selected)
        
        showInitials(groupContact: groupContact)
        
        contactImageView.sd_cancelCurrentImageLoad()
        
        if let imageUrl = groupContact.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
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
    
    func shouldAllowDelete() -> Bool {
        return (chat?.isPublicGroup() ?? false) && !(contact?.isOwner ?? false) && !pendingContact
    }
    
    func configureDeleteButton(showDelete: Bool = false) {
        
        numberOfButtons = .oneButton
        button3 = button1
        button1.tintColorDidChange()
        isSwipeEnabled = showDelete
    }
    
    func showInitials(groupContact: GroupAllContactsDataSource.GroupContact) {
        let senderNickname = contact.getName()
        let senderColor = contact.getColor()
        
        contactInitialsLabel.isHidden = false
        contactImageView.isHidden = true
        contactInitialsLabel.backgroundColor = senderColor
        contactInitialsLabel.textColor = UIColor.white
        contactInitialsLabel.text = senderNickname.getInitialsFromName()
    }
    
    func hideCheckBox() {
        checkboxLabel.isHidden = true
    }
    
    func configureCheckbox(selected: Bool) {
        checkboxLabel.text = selected ? "" : ""
        checkboxLabel.textColor = selected ? UIColor.Sphinx.PrimaryBlue : UIColor.Sphinx.OldReceivedMsgBG
    }
    
    func configureInitial(nickname: String?, firstOnLetter: Bool) {
        letterLabel.text = String(nickname?.first ?? ("name.unknown".localized.first ?? "U"))
        letterLabel.isHidden = !firstOnLetter
    }
    
    @IBAction func deleteButtonTouched() {
        let showDelete = shouldAllowDelete()
        
        guard let contact = contact, showDelete else {
            return
        }
        delegate?.didKickContact(contact: contact, cell: self)
    }
    
    @IBAction func pendingApprovalButtonTouched(_ sender: UIButton) {
        guard let contact = contact, let chat = chat else {
            return
        }
        
        guard let message = TransactionMessage.getLastGroupRequestFor(contactId: contact.id, in: chat) else {
            return
        }
        
        isUserInteractionEnabled = false
        
        switch (sender.tag) {
        case Button.Approve.rawValue:
            delegate?.shouldApproveMember(contact, requestMessage: message)
            break
        case Button.Reject.rawValue:
            delegate?.shouldRejectMember(contact, requestMessage: message)
            break
        default:
            break
        }
    }
}
