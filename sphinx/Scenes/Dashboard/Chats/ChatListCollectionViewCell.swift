import UIKit


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
    @IBOutlet weak var invitePriceContainer: UIView!
    @IBOutlet weak var invitePriceLabel: UILabel!
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var unreadMessageBadgeContainer: UIView!
    @IBOutlet weak var unreadMessageBadgeLabel: UILabel!
    
    
    var chatListObject: ChatListCommonObject? {
        didSet {
            guard let chatListObject = chatListObject else { return }
            DispatchQueue.main.async {
                self.render(with: chatListObject)
                
            }
        }
    }
}


// MARK: -  Lifecycle
extension ChatListCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
}


// MARK: -  Computeds
extension ChatListCollectionViewCell {
    
    var unreadMessageCount: Int {
        chatListObject?.getChat()?.getReceivedUnseenMessagesCount() ?? 0
    }
    
    var hasUnreadMessages: Bool { unreadMessageCount > 0 }
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
        unreadMessageBadgeContainer.makeCircular()
        
        invitePriceContainer.layer.cornerRadius = 2
        invitePriceContainer.clipsToBounds = true
        
        // Clear initial contents
        unreadMessageBadgeContainer.alpha = 0
        nameLabel.text = ""
        messageLabel.text = ""
        dateLabel.text = ""
        lockSign.isHidden = true
        muteImageView.isHidden = true
        inviteIcon.isHidden = true
        invitePriceContainer.isHidden = true
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
        renderContactImageViews(for: chatListObject)
        renderInvitePrice(for: chatListObject)
    }
    
    
    
    private func renderBadgeView(for chatListObject: ChatListCommonObject) {
        guard hasUnreadMessages else {
            unreadMessageBadgeContainer.alpha = 0
            return
        }
        
        guard chatListObject.isConfirmed() else {
            unreadMessageBadgeContainer.alpha = 0
            return
        }
        
        unreadMessageBadgeContainer.alpha = 1
        unreadMessageBadgeLabel.text = unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)"
        
        if chatListObject.getChat()?.isMuted() == true {
            unreadMessageBadgeContainer.alpha = 0.2
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.WashedOutReceivedText
        } else {
            unreadMessageBadgeContainer.alpha = 1.0
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.PrimaryBlue
        }
    }
    
    
    private func renderContactImageViews(for chatListObject: ChatListCommonObject) {
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
                        completed: { [unowned self] (_,_,_,_) in
                            self.contactInitialsLabel.isHidden = true
                            self.contactImageView.isHidden = false
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
            
            messageLabel.text = text
            dateLabel.isHidden = true
            
            messageLabel.font = Constants.kNewMessagePreviewFont
            messageLabel.textColor = .Sphinx.TextMessages
            
        } else {
            
            inviteIcon.isHidden = true
            
            if chatListObject.lastMessage == nil {
                chatListObject.getChat()?.updateLastMessage()
            }
            
            if let lastMessage = chatListObject.lastMessage {
                messageLabel.isHidden = false
                dateLabel.isHidden = false
                
                messageLabel.font = hasUnreadMessages ?
                    Constants.kNewMessagePreviewFont
                    : Constants.kMessagePreviewFont
                
                messageLabel.textColor = hasUnreadMessages ?
                    .Sphinx.TextMessages
                    : .Sphinx.SecondaryText
                
                messageLabel.text = lastMessage.getMessageDescription(dashboard: true)
                dateLabel.text = lastMessage.date.getLastMessageDateFormat()
            } else {
                messageLabel.isHidden = true
                dateLabel.isHidden = true
            }
        }
    }
    
    private func renderInvitePrice(for chatListObject: ChatListCommonObject) {
        if let invite = chatListObject.getInvite(),
           let price = invite.price,
           chatListObject.isPending() && invite.isPendingPayment() {
            
            invitePriceContainer.isHidden = false
            invitePriceLabel.text = Int(truncating: price).formattedWithSeparator
        } else {
            invitePriceContainer.isHidden = true
        }
    }
}


// MARK: - Static Properties
extension ChatListCollectionViewCell {
    static let reuseID = "ChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ChatListCollectionViewCell", bundle: nil)
    }()
}
