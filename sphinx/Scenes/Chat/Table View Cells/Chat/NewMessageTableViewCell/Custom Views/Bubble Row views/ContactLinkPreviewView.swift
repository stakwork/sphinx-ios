//
//  ContactLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class ContactLinkPreviewView: UIView {
    
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
    let kNewContactBubbleHeight: CGFloat = 156
    
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
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        configureColors(incoming: bubble.direction.isIncoming())
        
        addContactButtonContainer.isHidden = contactLink.isContact
        contentView.backgroundColor = contactLink.isContact ? UIColor.clear : UIColor.Sphinx.Body
        
        contactPubKey.text = contactLink.pubkey
        contactName.text = contactLink.alias ?? "new.contact".localized
        
        borderView.removeDashedLineBorderWith(name: kDashedLayerName)
        
        if contactLink.isContact {
            loadImage(imageUrl: contactLink.imageUrl)
        } else {
            contactImageView.image = UIImage(named: "addContactIcon")
            
            borderView.addDashedLineBorder(
                color: bubble.direction.isIncoming() ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.SentMsgBG,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: contactLink.bubbleWidth,
                    height: kNewContactBubbleHeight
                ),
                roundedBottom: contactLink.roundedBottom,
                roundedTop: false,
                name: kDashedLayerName
            )
        }
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
        if let contact = contact {
            loadImage(imageUrl: contact.getPhotoUrl()?.removeDuplicatedProtocol())
        } else {
            contactImageView.image = UIImage(named: "addContactIcon")
        }
    }
    
    func loadImage(imageUrl: String?) {
        contactImageView.sd_cancelCurrentImageLoad()
        
        if let image = imageUrl, let url = URL(string: image) {
            let transformer = SDImageResizingTransformer(
                size: CGSize(width: contactImageView.bounds.size.width * 3, height: contactImageView.bounds.size.height * 3),
                scaleMode: .aspectFill
            )
            
            contactImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    self.contactImageView.image = (error == nil) ? image : UIImage(named: "profile_avatar")
                }
            )
        } else {
            contactImageView.image = UIImage(named: "profile_avatar")
            contactImageView.contentMode = .scaleAspectFill
        }
    }
    
    @IBAction func addContactButtonTapped() {
        delegate?.didTapOnContactButton()
    }
}
