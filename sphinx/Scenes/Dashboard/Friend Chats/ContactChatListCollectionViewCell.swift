import UIKit

private let sampleLastMessage: TransactionMessage = {
    let managedObjectContext = CoreDataManager
        .sharedManager
        .persistentContainer
        .viewContext
    
    let message = TransactionMessage(context: managedObjectContext)
    
    message.id = -11
    message.createdAt = Date()
    message.updatedAt = Date()
    message.receiverId = 1
    message.senderId = 1
    message.amount = 1
    message.amountMsat = 1
    message.type = TransactionMessage.TransactionMessageType.message.rawValue
    message.status = 1
    message.date = Date()
    message.expirationDate = nil
    message.paymentHash = "xxxxxxxx"
    message.invoice = "xxxxxxxx"
    message.messageContent = "This is a sample last message that should ultimately be read dynamically."
    message.seen = false
    message.encrypted = true
    message.senderAlias = "<Sender>"
    message.senderPic = nil
    message.uuid = UUID().uuidString
    message.replyUUID = UUID().uuidString
    message.originalMuid = UUID().uuidString
    message.chat = nil
    message.mediaKey = nil
    message.mediaType = nil
    message.mediaToken = nil
    message.mediaFileName = nil
    message.mediaFileSize = 1024
    message.muid = nil
    
    return message
}()


class ContactChatListCollectionViewCell: UICollectionViewCell {
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
    
    
    var chat: Chat? {
        didSet {
            guard let chat = chat else { return }
            DispatchQueue.main.async { self.render(with: chat) }
        }
    }
}


// MARK: -  Lifecycle
extension ContactChatListCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
}


// MARK: -  Computeds
extension ContactChatListCollectionViewCell {
    
    var unreadMessageCount: Int {
        chat?.getConversation()?.getReceivedUnseenMessagesCount() ?? 0
    }
    
    var hasUnreadMessages: Bool { unreadMessageCount > 0 }
}



// MARK: -  Private Helpers
extension ContactChatListCollectionViewCell {
    
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
    }
    
    
    private func render(with chat: Chat) {
        if hasUnreadMessages {
            nameLabel.font = nameLabel.font.bold()
        }
        
        nameLabel.text = chat.getName()
        muteImageView.isHidden = chat.isMuted() == false
        lockSign.isHidden = chat.hasEncryptionKey() == false

        
        renderLastMessage(with: chat)
        renderBadgeView(with: chat)
        renderContactImageViews(with: chat)
    }
    
    
    
    private func renderBadgeView(with chat: Chat) {
        guard hasUnreadMessages else {
            unreadMessageBadgeContainer.alpha = 0
            return
        }
        
        unreadMessageBadgeContainer.alpha = 1
        unreadMessageBadgeLabel.text = unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)"
        
        if chat.isMuted() {
            unreadMessageBadgeContainer.alpha = 0.2
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.WashedOutReceivedText
            unreadMessageBadgeLabel.textColor = .Sphinx.WashedOutReceivedText
        } else {
            unreadMessageBadgeContainer.alpha = 1.0
            unreadMessageBadgeContainer.backgroundColor = .Sphinx.PrimaryBlue
            unreadMessageBadgeLabel.textColor = .Sphinx.PrimaryText
        }
    }
    
    
    private func renderContactImageViews(with chat: Chat) {
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
    
    
    private func renderContactInitialsLabel(for chat: Chat) {
        let senderInitials = chat.getName().getInitialsFromName()
        let senderColor = chat.getColor()
        
        contactInitialsLabel.backgroundColor = senderColor
        contactInitialsLabel.textColor = .white
        contactInitialsLabel.text = senderInitials
    }
    
    
    private func renderLastMessage(with chat: Chat) {
        let lastMessage = sampleLastMessage
        
        if true {
//        if let lastMessage = chat.lastMessage {
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
extension ContactChatListCollectionViewCell {
    static let reuseID = "ContactChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ContactChatListCollectionViewCell", bundle: nil)
    }()
}
