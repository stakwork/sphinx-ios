import UIKit

protocol ChatListCollectionViewCellDelegate : NSObject{
    func didLongPressOnCell(chatListObject: ChatListCommonObject, owner: UserContact, indexPath: IndexPath)
}

class ChatListCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var contactImageContainer: UIView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitialsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var inviteIcon: UILabel!
    @IBOutlet weak var failedMessageIcon: UILabel!
    @IBOutlet weak var invitePriceContainer: UIView!
    @IBOutlet weak var invitePriceLabel: UILabel!
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var unreadMessageBadgeContainer: UIView!
    @IBOutlet weak var unreadMessageBadgeLabel: UILabel!
    @IBOutlet weak var mentionsBadgeContainer: UIView!
    @IBOutlet weak var mentionsBadgeLabel: UILabel!
    
    var delegate : ChatListCollectionViewCellDelegate? = nil
    
    var chatListObject: ChatListCommonObject? {
        didSet {
            guard let chatListObject = chatListObject else { return }
            DispatchQueue.main.async {
                self.render(with: chatListObject)
  
            }
        }
    }
    
    var owner: UserContact!
    var indexPath: IndexPath? = nil
}


// MARK: -  Lifecycle
extension ChatListCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
}


// MARK: -  Computeds
extension ChatListCollectionViewCell {
    
    var unreadMessageCount: Int {
        if chatListObject?.isSeen(ownerId: owner.id) == true {
            return 0
        }
        return chatListObject?.getChat()?.getReceivedUnseenMessagesCount() ?? 0
    }
    
    var hasUnreadMessages: Bool { unreadMessageCount > 0 }
    
    var unreadMentionsCount: Int {
        if chatListObject?.isSeen(ownerId: owner.id) == true {
            return 0
        }
        return chatListObject?.getChat()?.getReceivedUnseenMentionsCount() ?? 0
    }
    
    var hasUnreadMentions: Bool { unreadMentionsCount > 0 }
}



// MARK: -  Private Helpers
extension ChatListCollectionViewCell {
    
    func setupViews() {
        let normalStateView = UIView(frame: bounds)
        normalStateView.backgroundColor = .Sphinx.DashboardHeader
        self.backgroundView = normalStateView

        let selectedStateView = UIView(frame: bounds)
        selectedStateView.backgroundColor = .Sphinx.DashboardSearch
        self.selectedBackgroundView = selectedStateView
        
        contactImageView.makeCircular()
        contactInitialsLabel.makeCircular()
        
        unreadMessageBadgeContainer.layer.cornerRadius = unreadMessageBadgeContainer.frame.height/2
        mentionsBadgeContainer.layer.cornerRadius = mentionsBadgeContainer.frame.height/2
        
        invitePriceContainer.layer.cornerRadius = 2
        invitePriceContainer.clipsToBounds = true
        
        // Clear initial contents
        unreadMessageBadgeContainer.isHidden = true
        mentionsBadgeContainer.isHidden = true
        nameLabel.text = ""
        messageLabel.text = ""
        dateLabel.text = ""
        lockSign.isHidden = true
        muteImageView.isHidden = true
        inviteIcon.isHidden = true
        invitePriceContainer.isHidden = true
        failedMessageIcon.isHidden = true
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.addGestureRecognizer(lpgr)
    }
    
    
    private func render(with chatListObject: ChatListCommonObject) {
        
        nameLabel.font = Constants.kChatNameFont
        
        if chatListObject.isPending() {
            
            let inviteString = String(
                format: "invite.name".localized,
                chatListObject.getName()
            )
            nameLabel.text = inviteString
            
            muteImageView.isHidden = true
            lockSign.isHidden = true
            
        } else {
            
            if hasUnreadMessages {
                nameLabel.font = nameLabel.font.bold()
            }
            
            nameLabel.text = chatListObject.getName()
            muteImageView.isHidden = (chatListObject.getChat()?.isMuted() ?? false) == false
            lockSign.isHidden = chatListObject.hasEncryptionKey() == false
        }
        
        renderLastMessage(for: chatListObject)
        renderBadgeView(for: chatListObject)
        renderMentionsView(for: chatListObject)
        renderContactImageViews(for: chatListObject)
        renderInvitePrice(for: chatListObject)
    }
    
    
    private func renderBadgeView(for chatListObject: ChatListCommonObject) {
        guard hasUnreadMessages else {
            unreadMessageBadgeContainer.isHidden = true
            return
        }
        
        guard chatListObject.isConfirmed() else {
            unreadMessageBadgeContainer.isHidden = true
            return
        }
        
        unreadMessageBadgeContainer.isHidden = false
        
        let unreadMCount = unreadMessageCount
        unreadMessageBadgeLabel.text = unreadMCount > 99 ? "99+" : "\(unreadMCount)"
        
        if chatListObject.getChat()?.isMuted() == true || chatListObject.getChat()?.isOnlyMentions() == true {
            unreadMessageBadgeContainer.alpha = 0.2
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.WashedOutReceivedText
        } else {
            unreadMessageBadgeContainer.alpha = 1.0
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.PrimaryBlue
        }
    }

    private func renderMentionsView(for chatListObject: ChatListCommonObject) {
        guard hasUnreadMentions else {
            mentionsBadgeContainer.isHidden = true
            return
        }
        
        guard chatListObject.isConfirmed() else {
            mentionsBadgeContainer.isHidden = true
            return
        }
        
        mentionsBadgeContainer.isHidden = false
        
        let unreadMCount = unreadMentionsCount
        mentionsBadgeLabel.text = unreadMCount > 99 ? "@ 99+" : "@ \(unreadMCount)"
    }
    
    private func renderContactImageViews(for chatListObject: ChatListCommonObject) {
        
        contactImageView.sd_cancelCurrentImageLoad()
        
        if chatListObject.isPending() {
            
            contactImageView.tintColor = UIColor.Sphinx.TextMessages
            contactImageView.tintColorDidChange()
            contactImageView.layer.cornerRadius = 0
            contactImageView.clipsToBounds = true
            
            contactInitialsLabel.isHidden = true
            contactImageView.isHidden = false
            contactImageView.image = UIImage(named: "inviteQrCode")
            
        } else {
            
            contactImageView.layer.cornerRadius = contactImageView.frame.height / 2
            contactImageView.clipsToBounds = true
        
            if let image = chatListObject.getImage() {
                contactInitialsLabel.isHidden = true
                contactImageView.isHidden = false
                contactImageView.image = image
            } else {
                contactInitialsLabel.isHidden = false
                contactImageView.isHidden = true
                renderContactInitialsLabel(for: chatListObject)

                if
                    let imageURLPath = chatListObject.getPhotoUrl()?.removeDuplicatedProtocol(),
                    let imageURL = URL(string: imageURLPath)
                {
                    contactImageView.sd_setImage(
                        with: imageURL,
                        placeholderImage: UIImage(named: "profile_avatar"),
                        options: .lowPriority,
                        progress: nil,
                        completed: { [unowned self] (image, error,_,_) in
                            if (error == nil) {
                                self.contactInitialsLabel.isHidden = true
                                self.contactImageView.isHidden = false
                                self.contactImageView.image = image
                            }
                        }
                    )
                }
            }
        }
    }
    
    
    private func renderContactInitialsLabel(for chatListObject: ChatListCommonObject) {
        let senderInitials = chatListObject.getName().getInitialsFromName()
        let senderColor = chatListObject.getColor()
        
        contactInitialsLabel.backgroundColor = senderColor
        contactInitialsLabel.textColor = .white
        contactInitialsLabel.text = senderInitials
    }
    
    
    private func renderLastMessage(for chatListObject: ChatListCommonObject) {
        if let invite = chatListObject.getInvite(), chatListObject.isPending() {
            
            let (icon, iconColor, text) = invite.getDataForRow()
            
            inviteIcon.text = icon
            inviteIcon.textColor = iconColor
            inviteIcon.isHidden = false
            failedMessageIcon.isHidden = true
            
            messageLabel.superview?.isHidden = false
            messageLabel.text = text
            dateLabel.isHidden = true
            
            messageLabel.font = Constants.kNewMessagePreviewFont
            messageLabel.textColor = .Sphinx.TextMessages
            
        } else {
            
            inviteIcon.isHidden = true
            failedMessageIcon.isHidden = true
            
            if let lastMessage = chatListObject.lastMessage {
                
                let isFailedMessage = lastMessage.failed()
                
                messageLabel.font = hasUnreadMessages ?
                    Constants.kNewMessagePreviewFont
                    : Constants.kMessagePreviewFont
                if isFailedMessage {
                    messageLabel.textColor = .Sphinx.PrimaryRed
                } else {
                    messageLabel.textColor = hasUnreadMessages ?
                        .Sphinx.TextMessages
                        : .Sphinx.SecondaryText
                }
                
                messageLabel.text = lastMessage.getMessageContentPreview(
                    owner: self.owner,
                    contact: chatListObject.getContact()
                )
                dateLabel.text = lastMessage.messageDate.getLastMessageDateFormat()
                
                messageLabel.superview?.isHidden = false
                dateLabel.isHidden = false
                
                failedMessageIcon.isHidden = !isFailedMessage
            } else {
                messageLabel.superview?.isHidden = true
                dateLabel.isHidden = true
            }
        }
    }
    
    private func renderInvitePrice(for chatListObject: ChatListCommonObject) {
        if let invite = chatListObject.getInvite(),
           let price = invite.price,
           chatListObject.isPending() && invite.isPendingPayment() && !invite.isPaymentProcessed() {
            
            invitePriceContainer.isHidden = false
            invitePriceLabel.text = Int(truncating: price).formattedWithSeparator
        } else {
            invitePriceContainer.isHidden = true
        }
    }
    
    @objc func handleLongPress() {
        guard let delegate = delegate,
              let chatListObject = chatListObject,
              let indexPath = indexPath else {
            return
        }
        delegate.didLongPressOnCell(chatListObject: chatListObject, owner: owner, indexPath: indexPath)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        chatListObject = nil
        indexPath = nil
    }
}


// MARK: - Static Properties
extension ChatListCollectionViewCell {
    static let reuseID = "ChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ChatListCollectionViewCell", bundle: nil)
    }()
}
