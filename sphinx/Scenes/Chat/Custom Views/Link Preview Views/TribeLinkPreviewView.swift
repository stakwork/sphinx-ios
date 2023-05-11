//
//  TribeLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol LinkPreviewDelegate: class {
    func didTapOnTribeButton()
    func didTapOnContactButton()
}

class TribeLinkPreviewView: LinkPreviewBubbleView {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var tribeImageView: UIImageView!
    @IBOutlet weak var tribeNameLabel: UILabel!
    @IBOutlet weak var tribeDescriptionTextView: UITextView!
    @IBOutlet weak var containerButton: UIButton!
    @IBOutlet weak var tribeButtonContainer: UIView!
    
    var messageId: Int = -1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("TribeLinkPreviewView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        tribeDescriptionTextView.textContainer.lineFragmentPadding = 0
        tribeDescriptionTextView.textContainerInset = .zero
        tribeDescriptionTextView.contentInset = .zero
        tribeDescriptionTextView.clipsToBounds = true
        
        tribeButtonContainer.layer.cornerRadius = 3
        
        tribeImageView.layer.cornerRadius = 3
        tribeImageView.clipsToBounds = true
        tribeImageView.layer.borderWidth = 1
        tribeImageView.layer.borderColor = UIColor.Sphinx.SecondaryText.withAlphaComponent(0.5).resolvedCGColor(with: self)
    }
    
    func configurePreview(messageRow: TransactionMessageRow, delegate: LinkPreviewDelegate, doneCompletion: @escaping (Int) -> ()) {
        messageId = messageRow.transactionMessage.id
        
        let link = messageRow.getMessageContent().stringFirstTribeLink
        loadTribeDetails(link: link, completion: { tribeInfo in
            if let tribeInfo = tribeInfo {
                messageRow.transactionMessage.tribeInfo = tribeInfo
                doneCompletion(self.messageId)
            }
        })
    }
    
    func configureView(messageRow: TransactionMessageRow, tribeInfo: GroupsManager.TribeInfo?, delegate: LinkPreviewDelegate) {
        guard let tribeInfo = tribeInfo else {
            return
        }
        self.delegate = delegate
        
        configureColors(messageRow: messageRow)
        addBubble(messageRow: messageRow)
        
        tribeButtonContainer?.isHidden = messageRow.isJoinedTribeLink(uuid: tribeInfo.uuid)
        tribeNameLabel.text = tribeInfo.name ?? "title.not.available".localized
        tribeDescriptionTextView.text = tribeInfo.description ?? "description.not.available".localized

        loadImage(tribeInfo: tribeInfo)
    }
    
    func configureColors(messageRow: TransactionMessageRow) {
        let incoming = messageRow.isIncoming()
        let color = incoming ? UIColor.Sphinx.SecondaryText : UIColor.Sphinx.SecondaryTextSent
        tribeDescriptionTextView.textColor = color
        tribeImageView.tintColor = color
        tribeImageView.layer.borderColor = color.resolvedCGColor(with: self)
        
        let buttonColor = incoming ? UIColor.Sphinx.LinkReceivedButtonColor : UIColor.Sphinx.LinkSentButtonColor
        tribeButtonContainer.backgroundColor = buttonColor
    }
    
    func loadImage(tribeInfo: GroupsManager.TribeInfo?) {
        guard let tribeInfo = tribeInfo, let imageUrlString = tribeInfo.img, let imageUrl = URL(string: imageUrlString) else {
            tribeImageView.contentMode = .center
            tribeImageView.image = UIImage(named: "tribePlaceholder")
            tribeImageView.layer.borderWidth = 1
            return
        }
        MediaLoader.asyncLoadImage(imageView: tribeImageView, nsUrl: imageUrl, placeHolderImage: UIImage(named: "tribePlaceholder"), completion: { image in
            MediaLoader.storeImageInCache(img: image, url: imageUrlString, chat: nil)
            self.tribeImageView.image = image
            self.tribeImageView.layer.borderWidth = 0
            self.tribeImageView.contentMode = .scaleAspectFill
        }, errorCompletion: { _ in
            self.tribeImageView.image = UIImage(named: "tribePlaceholder")
            self.tribeImageView.contentMode = .center
        })
        
    }
    
    func loadTribeDetails(link: String, completion: @escaping (GroupsManager.TribeInfo?) -> ()) {
        if var tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: link) {
            API.sharedInstance.getTribeInfo(host: tribeInfo.host, uuid: tribeInfo.uuid, callback: { groupInfo in
                GroupsManager.sharedInstance.update(tribeInfo: &tribeInfo, from: groupInfo)
                completion(tribeInfo)
            }, errorCallback: {
                completion(nil)
            })
            return
        }
        completion(nil)
    }
    
    func addBubble(messageRow: TransactionMessageRow) {
        let width = getViewWidth(messageRow: messageRow)
        let height = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
        let bubbleSize = CGSize(width: width, height: height)
        
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: true, nextBubble: false)
        let existingObject = messageRow.isJoinedTribeLink()

        if messageRow.isIncoming() {
            self.showIncomingLinkBubble(contentView: contentView, messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        } else {
            self.showOutgoingLinkBubble(contentView: contentView, messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        }
        
        self.contentView.bringSubviewToFront(tribeImageView)
        self.contentView.bringSubviewToFront(tribeNameLabel)
        self.contentView.bringSubviewToFront(tribeDescriptionTextView)
        self.contentView.bringSubviewToFront(tribeButtonContainer)
        self.contentView.bringSubviewToFront(containerButton)
    }
    
    @IBAction func seeTribeButtonTouched() {
        delegate?.didTapOnTribeButton()
    }
}
