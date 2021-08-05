import UIKit

private let sampleLastMessage: TransactionMessage = {
    let managedObjectContext = CoreDataManager
        .sharedManager
        .persistentContainer
        .viewContext
    
    let message = TransactionMessage(context: managedObjectContext)
    
    message.id = 11
    message.createdAt = Date()
    message.updatedAt = Date()
    message.receiverId = 1
    message.senderId = 1
    message.amount = 1
    message.amountMsat = 1
    message.type = 1
    message.status = 1
    message.date = Date()
    message.expirationDate = nil
    message.paymentHash = "xxxxxxxx"
    message.invoice = "xxxxxxxx"
    message.messageContent = "This is a sample last message that should ultimately be read dynamically."
    message.seen = false
    message.encrypted = true
    message.senderAlias = nil
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
    //    @IBOutlet weak var nameTopConstraint: NSLayoutConstraint!
    //    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var signLabel: UILabel!
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var nameRightConstraint: NSLayoutConstraint!
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
    }
    
    
    private func render(with chat: Chat) {
        if hasUnreadMessages {
            nameLabel.font = nameLabel.font.bold()
        }
        
        nameLabel.text = chat.getName()
        
        configureLastMessage(for: chat)
        configureBadgeView(with: chat)
        configureContactImageViews(with: chat)
    }
    
    
    
    private func configureBadgeView(with chat: Chat) {
        guard hasUnreadMessages else {
//            unreadMessageBadgeContainer.isHidden = true
            unreadMessageBadgeContainer.alpha = 0
            return
        }
        
        unreadMessageBadgeContainer.alpha = 1
//        unreadMessageBadgeContainer.isHidden = false
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
    
    
    private func configureContactImageViews(with chat: Chat) {
        if let avatarImage = chat.image {
            contactImageView.isHidden = false
            contactInitialsLabel.isHidden = true
            contactImageView.image = avatarImage
        } else {
            contactImageView.isHidden = true
            contactInitialsLabel.isHidden = false
            configureContactInitialsLabel(for: chat)
        }
        
    }
    
    
    private func configureContactInitialsLabel(for chat: Chat) {
        let senderInitials = chat.getName().getInitialsFromName()
        let senderColor = chat.getColor()
        
        contactInitialsLabel.backgroundColor = senderColor
        contactInitialsLabel.textColor = .white
        contactInitialsLabel.text = senderInitials
    }
    
    
    private func configureLastMessage(for chat: Chat) {
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
            
            //            nameTopConstraint.constant = Constants.kChatListNamePosition
        } else {
//            messageLabel.isHidden = true
//            dateLabel.isHidden = true
            
            messageLabel.alpha = 0
            dateLabel.alpha = 0
            //            nameTopConstraint.constant = 0
        }
        
        //        messageLabel.adjustsFontSizeToFitWidth = false;
        //        messageLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        //        messageBottomConstraint.constant = Constants.kChatListMessagePosition
        
        //        nameLabel.superview?.layoutIfNeeded()
    }
    
}




// MARK: - Static Properties
extension ContactChatListCollectionViewCell {
    static let reuseID = "ContactChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ContactChatListCollectionViewCell", bundle: nil)
    }()
}
