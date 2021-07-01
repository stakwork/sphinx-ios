//
//  ContactLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/12/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class ContactLinkPreviewView: LinkPreviewBubbleView {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var contactPubKey: UILabel!
    @IBOutlet weak var contactPubkeyIcon: UIImageView!
    @IBOutlet weak var addContactButtonContainer: UIView!
    @IBOutlet weak var containerButton: UIButton!
    
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
        
        addContactButtonContainer.layer.cornerRadius = 3
        
        contactImageView.layer.cornerRadius = contactImageView.frame.height / 2
        contactImageView.clipsToBounds = true
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
        let color = incoming ? UIColor.Sphinx.SecondaryText : UIColor.Sphinx.SecondaryTextSent
        contactPubKey.textColor = color
        contactPubkeyIcon.tintColor = color
        contactImageView.tintColor = color
        contactPubkeyIcon.tintColorDidChange()
        contactImageView.tintColorDidChange()

        let buttonColor = incoming ? UIColor.Sphinx.LinkReceivedButtonColor : UIColor.Sphinx.LinkSentButtonColor
        addContactButtonContainer.backgroundColor = buttonColor
    }
    
    func loadImage(contact: UserContact?) {
        guard let contact = contact, let imageUrlString = contact.getPhotoUrl()?.removeDuplicatedProtocol(), let imageUrl = URL(string: imageUrlString) else {
            self.contactImageView.image = UIImage(named: "addContactIcon")
            return
        }
        MediaLoader.asyncLoadImage(imageView: contactImageView, nsUrl: imageUrl, placeHolderImage: UIImage(named: "addContactIcon"), completion: { image in
            MediaLoader.storeImageInCache(img: image, url: imageUrlString)
            self.contactImageView.image = image
        }, errorCompletion: { _ in })
        
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
    
    @IBAction func addContactButtonTapped() {
        delegate?.didTapOnContactButton()
    }
}
