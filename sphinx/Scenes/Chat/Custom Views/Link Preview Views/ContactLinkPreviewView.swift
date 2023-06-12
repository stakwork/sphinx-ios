//
//  ContactLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class ContactLinkPreviewView: LinkPreviewBubbleView {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var contactPubKey: UILabel!
    @IBOutlet weak var contactPubkeyIcon: UIImageView!
    @IBOutlet weak var addContactButtonContainer: UIView!
    @IBOutlet weak var addContactButtonView: UIView!
    @IBOutlet weak var containerButton: UIButton!
    @IBOutlet weak var borderView: UIView!
    
    let kDashedLayerName = "dashed-layer"
    let kNewContactBubbleHeight: CGFloat = 168
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("ContactLinkPreviewView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        addContactButtonView.layer.cornerRadius = 3
        
        contactImageView.layer.cornerRadius = contactImageView.frame.height / 2
        contactImageView.clipsToBounds = true
    }
    
    func configureWith(
        contactLink: BubbleMessageLayoutState.ContactLink,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        configureColors(incoming: bubble.direction.isIncoming())
        
        addContactButtonContainer.isHidden = contactLink.isContact
        contentView.backgroundColor = contactLink.isContact ? UIColor.clear : UIColor.Sphinx.Body
        
        contactPubKey.text = contactLink.pubkey
        contactName.text = contactLink.alias ?? "new.contact".localized

        loadImage(imageUrl: contactLink.imageUrl)
        
        removeDashedLineBorder()
        
        if !contactLink.isContact {
            addDashedLineBorder(
                color: bubble.direction.isIncoming() ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.SentMsgBG,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: contactLink.bubbleWidth,
                    height: kNewContactBubbleHeight
                ),
                roundedBottom: contactLink.roundedBottom
            )
        }
    }
    
    func configureView(messageRow: TransactionMessageRow, delegate: LinkPreviewDelegate) {
        self.delegate = delegate
        
        configureColors(messageRow: messageRow)
        addBubble(messageRow: messageRow)
        
        let (existing, contact) = messageRow.isExistingContactPubkey()
        addContactButtonContainer?.isHidden = existing
        contactName.text = contact?.getUserName() ?? "new.contact".localized
        contactPubKey.text = messageRow.getMessageContent().stringFirstPubKey

        loadImage(contact: contact)
    }
    
    func configureColors(messageRow: TransactionMessageRow) {
        let incoming = messageRow.isIncoming()
        configureColors(incoming: incoming)
    }
    
    func configureColors(incoming: Bool) {
        let color = incoming ? UIColor.Sphinx.SecondaryText : UIColor.Sphinx.SecondaryTextSent
        contactPubKey.textColor = color
        contactPubkeyIcon.tintColor = color
        contactImageView.tintColor = color
        contactPubkeyIcon.tintColorDidChange()
        contactImageView.tintColorDidChange()

        let buttonColor = incoming ? UIColor.Sphinx.LinkReceivedButtonColor : UIColor.Sphinx.LinkSentButtonColor
        addContactButtonView.backgroundColor = buttonColor
    }
    
    func loadImage(contact: UserContact?) {
        loadImage(imageUrl: contact?.getPhotoUrl()?.removeDuplicatedProtocol())
    }
    
    func loadImage(imageUrl: String?) {
        contactImageView.sd_cancelCurrentImageLoad()
        
        if let image = imageUrl, let url = URL(string: image) {
            let transformer = SDImageResizingTransformer(
                size: contactImageView.bounds.size,
                scaleMode: .aspectFill
            )
            
            contactImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "addContactIcon"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    self.contactImageView.image = (error == nil) ? image : UIImage(named: "addContactIcon")
                }
            )
        } else {
            contactImageView.image = UIImage(named: "addContactIcon")
        }
    }
    
    func addBubble(messageRow: TransactionMessageRow) {
        let width = getViewWidth(messageRow: messageRow)
        let height = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
        let bubbleSize = CGSize(width: width, height: height)
        
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: true, nextBubble: false)
        let existingObject = messageRow.isExistingContactPubkey().0

        if messageRow.isIncoming() {
            self.showIncomingLinkBubble(contentView: contentView, messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        } else {
            self.showOutgoingLinkBubble(contentView: contentView, messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        }
        
        self.contentView.bringSubviewToFront(contactImageView)
        self.contentView.bringSubviewToFront(contactName)
        self.contentView.bringSubviewToFront(contactPubKey)
        self.contentView.bringSubviewToFront(contactPubkeyIcon)
        self.contentView.bringSubviewToFront(addContactButtonContainer)
        self.contentView.bringSubviewToFront(containerButton)
    }
    
    func addDashedLineBorder(
        color: UIColor,
        rect: CGRect,
        roundedBottom: Bool
    ) {
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        shapeLayer.cornerRadius = 8.0
        shapeLayer.path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: roundedBottom ? [.bottomLeft, .bottomRight] : [],
            cornerRadii: CGSize(width: 8.0, height: 8.0)
        ).cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.resolvedCGColor(with: contentView)
        shapeLayer.lineWidth = 1.5
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = [8,4]
        shapeLayer.name = kDashedLayerName
        
        borderView.layer.addSublayer(shapeLayer)
    }
    
    func removeDashedLineBorder() {
        for sublayer in borderView.layer.sublayers ?? [] {
            if sublayer.name == kDashedLayerName {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    @IBAction func addContactButtonTapped() {
        delegate?.didTapOnContactButton()
    }
}
