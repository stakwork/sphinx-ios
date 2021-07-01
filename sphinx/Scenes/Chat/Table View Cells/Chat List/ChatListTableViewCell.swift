//
//  Library
//
//  Created by Tomas Timinskas on 07/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class ChatListTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileInitialsLabel: UILabel!
    @IBOutlet weak var groupImagesContainer: UIView!
    @IBOutlet weak var groupImage1: UIImageView!
    @IBOutlet weak var groupLabel1: UILabel!
    @IBOutlet weak var groupImage2: UIImageView!
    @IBOutlet weak var groupLabel2: UILabel!
    @IBOutlet weak var groupImage2Container: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var nameTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var signLabel: UILabel!
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var priceContainer: UIView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var badgeView: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    
    let lockSignWidht: CGFloat = 20.0
    let muteSignWidht: CGFloat = 20.0
    let rowRightMargin: CGFloat = 16.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if (highlighted) {
            self.contentView.backgroundColor = UIColor.Sphinx.ChatListSelected
        } else {
            self.contentView.backgroundColor = UIColor.Sphinx.HeaderBG
        }
    }
    
    func configureChatListRow(object: ChatListCommonObject, isLastRow: Bool = false) {
        let activeSubscription = object.subscribedToContact()
        
        profileImageView.layer.cornerRadius = activeSubscription ? 5 : profileImageView.frame.size.width/2
        profileImageView.clipsToBounds = true
        
        makeImagesCircular(images: [groupImage1, groupImage2, groupImage2Container, profileInitialsLabel, groupLabel1, groupLabel2])
        
        nameLabel.font = Constants.kChatNameFont
        nameLabel.text = object.getName()
        lockSign.isHidden = !object.hasEncryptionKey()
        signLabel.text = ""

        setImages(object: object)

        separatorLine.isHidden = isLastRow
        configureLastMessage(object: object)
        
        configureBadge(count: object.getConversation()?.getReceivedUnseenMessagesCount() ?? 0)
        
        muteImageView.isHidden = !(object.getConversation()?.isMuted() ?? false)
        
        resetPriceLayouts()
    }
    
    func setImages(object: ChatListCommonObject) {
        let shouldShowSingleImage = object.shouldShowSingleImage()
        let contacts = object.getChatContacts()
        
        profileImageContainer.isHidden = !shouldShowSingleImage
        groupImagesContainer.isHidden = shouldShowSingleImage
        
        func getContactWithIndex(contacts: [UserContact], index: Int) -> UserContact? {
            return contacts.count >= index + 1 ? contacts[index] : nil
        }

        if object.shouldShowSingleImage() {
            loadImageFor(object, in: profileImageView, and: profileInitialsLabel)
        } else {
            let orderedContacts = contacts.sorted(by: { (!$0.isOwner && $0.avatarUrl != nil) && ($1.isOwner || $1.avatarUrl == nil) })

            loadImageFor(getContactWithIndex(contacts: orderedContacts, index: 0), in: groupImage2, and: groupLabel2)
            loadImageFor(getContactWithIndex(contacts: orderedContacts, index: 1), in: groupImage1, and: groupLabel1)
        }
    }
    
    func loadImageFor(_ object: ChatListCommonObject?, in imageView: UIImageView, and initialLabel: UILabel) {
        imageView.isHidden = true
        initialLabel.isHidden = true
        
        imageView.image = UIImage(named: "profile_avatar")

        if let image = object?.getImage() {
            showImage(image: image, imageView: imageView, initialLabel: initialLabel)
        } else {
            showInitialsFor(object, in: initialLabel)

            if let urlString = object?.getPhotoUrl()?.removeDuplicatedProtocol(), let nsUrl = URL(string: urlString) {
                imageView.sd_setImage(with: nsUrl, placeholderImage: UIImage(named: "profile_avatar"), options: .lowPriority, progress: nil, completed: { (_,_,_,_) in
                    initialLabel.isHidden = true
                    imageView.isHidden = false
                })
            }
        }
    }
    
    func showImage(image: UIImage, imageView: UIImageView, initialLabel: UIView) {
        showImageView(imageView: imageView, initialLabel: initialLabel)
        imageView.image = image
    }
    
    func showImageView(imageView: UIImageView, initialLabel: UIView) {
        initialLabel.isHidden = true
        imageView.isHidden = false
    }
    
    func showInitialsFor(_ object: ChatListCommonObject?, in label: UILabel) {
        let senderInitials = object?.getName().getInitialsFromName() ?? "name.unknown.initials".localized
        let senderColor = object?.getColor()
        
        label.isHidden = false
        label.backgroundColor = senderColor
        label.textColor = UIColor.white
        label.text = senderInitials
    }
    
    func makeImagesCircular(images: [UIView]) {
        for image in images {
            image.layer.cornerRadius = image.frame.size.width/2
            image.clipsToBounds = true
        }
    }
    
    func resetPriceLayouts() {
        priceContainer.layer.cornerRadius = 3
        priceContainer.isHidden = true
        nameRightConstraint.constant = lockSignWidht + muteSignWidht + rowRightMargin
        nameLabel.superview?.layoutIfNeeded()
    }
    
    func configureLastMessage(object: ChatListCommonObject) {
        if let lastMessage = object.lastMessage {
            messageLabel.isHidden = false
            dateLabel.isHidden = false
            
            let newMessage = lastMessage.isNewUnseenMessage()
            messageLabel.font = newMessage ? Constants.kNewMessagePreviewFont : Constants.kMessagePreviewFont
            messageLabel.textColor = newMessage ? UIColor.Sphinx.TextMessages : UIColor.Sphinx.SecondaryText

            messageLabel.text = lastMessage.getMessageDescription(dashboard: true)
            dateLabel.text = lastMessage.date.getLastMessageDateFormat()
            nameTopConstraint.constant = Constants.kChatListNamePosition
        } else {
            messageLabel.isHidden = true
            dateLabel.isHidden = true
            nameTopConstraint.constant = 0
        }
        messageLabel.adjustsFontSizeToFitWidth = false;
        messageLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        messageBottomConstraint.constant = Constants.kChatListMessagePosition
        
        nameLabel.superview?.layoutIfNeeded()
    }
    
    func configureBadge(count: Int) {
        badgeView.layer.cornerRadius = badgeView.frame.size.height / 2
        badgeView.isHidden = count <= 0
        badgeLabel.text = count > 99 ? "99+" : "\(count)"
    }
    
    func configureInvitation(contact: UserContact, isLastRow: Bool = false) {
        let inviteString = String(format: "invite.name".localized, contact.nickname ?? "")
        
        nameLabel.text = inviteString
        messageLabel.text = contact.invite?.welcomeMessage ?? "welcome.to.sphinx".localized
        dateLabel.text = ""
        messageLabel.isHidden = false
        lockSign.isHidden = true
        badgeView.isHidden = true
        muteImageView.isHidden = true
        profileInitialsLabel.isHidden = true
        profileImageView.isHidden = false
        
        profileImageContainer.isHidden = false
        groupImagesContainer.isHidden = true
        
        profileImageView.stopRotating()
        profileImageView.tintColor = UIColor.Sphinx.TextMessages
        profileImageView.tintColorDidChange()
        profileImageView.layer.cornerRadius = 0
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "inviteQrCode")
        
        separatorLine.isHidden = isLastRow
        
        messageLabel.isHidden = false
        dateLabel.isHidden = false
        nameTopConstraint.constant = Constants.kChatListNamePosition
        nameLabel.superview?.layoutIfNeeded()
        
        resetPriceLayouts()
        configureInviteStatus(invite: contact.invite)
    }
    
    func configureInviteStatus(invite: UserInvite?) {        
        if let invite = invite {
            let (sign, color, text) = invite.getDataForRow()

            signLabel.text = sign
            signLabel.textColor = color
            messageLabel.text = text

            if let price = invite.price, invite.isPendingPayment(){
                priceContainer.isHidden = false
                priceLabel.text = Int(truncating: price).formattedWithSeparator
                nameRightConstraint.constant = lockSignWidht + muteSignWidht + rowRightMargin + priceContainer.frame.size.width
            }
            
            nameLabel.superview?.layoutIfNeeded()
        }
    }
}
