import UIKit

class ContactChatListCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var contactImageContainer: UIView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitialsLabel: UILabel!
//    @IBOutlet weak var groupImagesContainer: UIView!
//    @IBOutlet weak var groupImage1: UIImageView!
//    @IBOutlet weak var groupLabel1: UILabel!
//    @IBOutlet weak var groupImage2: UIImageView!
//    @IBOutlet weak var groupLabel2: UILabel!
//    @IBOutlet weak var groupImage2Container: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var separatorLine: UIView!
//    @IBOutlet weak var nameTopConstraint: NSLayoutConstraint!
//    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var signLabel: UILabel!
    @IBOutlet weak var muteImageView: UIImageView!
//    @IBOutlet weak var priceContainer: UIView!
//    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var unreadMessageBadgeContainer: UIView!
    @IBOutlet weak var unreadMessageBadgeLabel: UILabel!
    
    
    var chat: Chat? {
        didSet {
            guard let chat = chat else { return }
            DispatchQueue.main.async { self.render(with: chat) }
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()

        setupViews()
    }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
}

extension ContactChatListCollectionViewCell {
    
    func setupViews() {
        backgroundColor = .Sphinx.DashboardHeader
        backgroundView?.backgroundColor = .Sphinx.DashboardHeader
        
        contactImageView.makeCircular()
        contactInitialsLabel.makeCircular()
        unreadMessageBadgeContainer.makeCircular()
    }
    
    
    private func render(with chat: Chat) {
        nameLabel.font = Constants.kChatNameFont
        nameLabel.text = chat.getName()
        
//        messageLabel.text = chat.ongoingMessage
        messageLabel.text = chat.lastMessage?.messageContent
        
        configureBadgeView(with: chat)
        configureContactImageViews(with: chat)
    }
    
    
    
    private func configureBadgeView(with chat: Chat) {
        guard
            let count = chat.getConversation()?.getReceivedUnseenMessagesCount(),
            count > 0
        else {
            unreadMessageBadgeContainer.isHidden = true
            return
        }

        unreadMessageBadgeContainer.isHidden = false
        unreadMessageBadgeLabel.text = count > 99 ? "99+" : "\(count)"
        
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
    
}




// MARK: - Static Properties
extension ContactChatListCollectionViewCell {
    static let reuseID = "ContactChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ContactChatListCollectionViewCell", bundle: nil)
    }()
}
