import UIKit

class ContactChatListCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var contactImageContainer: UIView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitialsLabel: UILabel!
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
        backgroundView?.backgroundColor = .Sphinx.DashboardHeader
        
        contactImageView.clipsToBounds = true
        contactImageView.layer.cornerRadius = contactImageView.layer.frame.width / 2
    }
    
    
    private func render(with chat: Chat) {
        contactImageView.image = chat.image
        
        nameLabel.font = Constants.kChatNameFont
        nameLabel.text = chat.getName()
        
        messageLabel.text = chat.ongoingMessage
    }
}




// MARK: - Static Properties
extension ContactChatListCollectionViewCell {
    static let reuseID = "ContactChatListCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "ContactChatListCollectionViewCell", bundle: nil)
    }()
}
