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
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var unreadMessageBadgeContainer: UIView!
    @IBOutlet weak var unreadMessageBadgeLabel: UILabel!
    
    
    var chat: ChatListCommonObject? {
        didSet {
            guard let chat = chat else { return }
            DispatchQueue.main.async { self.render(with: chat) }
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
        chat?.getChat()?.getReceivedUnseenMessagesCount() ?? 0
    }
    
    var hasUnreadMessages: Bool { unreadMessageCount > 0 }
}



// MARK: -  Private Helpers
extension ChatListCollectionViewCell {
    
    func setupViews() {
        backgroundColor = .Sphinx.DashboardHeader
        backgroundView?.backgroundColor = .Sphinx.DashboardHeader
        
        contactImageView.makeCircular()
        contactInitialsLabel.makeCircular()
        unreadMessageBadgeContainer.makeCircular()
        
        // Clear initial contents
        unreadMessageBadgeContainer.alpha = 0
        nameLabel.text = ""
        messageLabel.text = ""
        dateLabel.text = ""
        lockSign.isHidden = true
        muteImageView.isHidden = true
    }
    
    
    private func render(with chat: ChatListCommonObject) {
        if hasUnreadMessages {
            nameLabel.font = nameLabel.font.bold()
        }
        
        nameLabel.text = chat.getName()
        muteImageView.isHidden = chat.getChat()?.isMuted() == false
        lockSign.isHidden = chat.hasEncryptionKey() == false

        
        renderLastMessage(for: chat)
        renderBadgeView(for: chat)
        renderContactImageViews(for: chat)
    }
    
    
    
    private func renderBadgeView(for chat: ChatListCommonObject) {
        guard hasUnreadMessages else {
            unreadMessageBadgeContainer.alpha = 0
            return
        }
        
        unreadMessageBadgeContainer.alpha = 1
        unreadMessageBadgeLabel.text = unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)"
        
        if chat.getChat()?.isMuted() == true {
            unreadMessageBadgeContainer.alpha = 0.2
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.WashedOutReceivedText
        } else {
            unreadMessageBadgeContainer.alpha = 1.0
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.PrimaryBlue
        }
    }
    
    
    private func renderContactImageViews(for chat: ChatListCommonObject) {
        if let image = chat.getImage() {
            contactInitialsLabel.isHidden = true
            contactImageView.isHidden = false
            contactImageView.image = image
        } else {
            contactInitialsLabel.isHidden = false
            contactImageView.isHidden = true
            renderContactInitialsLabel(for: chat)
            
            if
                let imageURLPath = chat.getPhotoUrl()?.removeDuplicatedProtocol(),
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
    
    
    private func renderContactInitialsLabel(for chat: ChatListCommonObject) {
        let senderInitials = chat.getName().getInitialsFromName()
        let senderColor = chat.getColor()
        
        contactInitialsLabel.backgroundColor = senderColor
        contactInitialsLabel.textColor = .white
        contactInitialsLabel.text = senderInitials
    }
    
    
    private func renderLastMessage(for chat: ChatListCommonObject) {
        if chat.lastMessage == nil {
            chat.getChat()?.updateLastMessage()
        }

        if let lastMessage = chat.lastMessage {
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


// MARK: - Static Properties
extension ChatListCollectionViewCell {
    static let reuseID = "ChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ChatListCollectionViewCell", bundle: nil)
    }()
}
