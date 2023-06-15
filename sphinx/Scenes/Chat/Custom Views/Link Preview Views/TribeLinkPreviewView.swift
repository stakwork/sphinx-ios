//
//  TribeLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

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
    @IBOutlet weak var tribeButtonView: UIView!
    @IBOutlet weak var borderView: UIView!
    
    let kDashedLayerName = "dashed-layer"
    let kNewTribeBubbleHeight: CGFloat = 165
    
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
        
        tribeButtonView.layer.cornerRadius = 3
        
        tribeImageView.layer.cornerRadius = 3
        tribeImageView.clipsToBounds = true
        tribeImageView.layer.borderWidth = 1
        tribeImageView.layer.borderColor = UIColor.Sphinx.SecondaryText.withAlphaComponent(0.5).resolvedCGColor(with: self)
    }
    
    func configureWith(
        tribeData: MessageTableCellState.TribeData,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        configureColors(incoming: bubble.direction.isIncoming())
        
        tribeButtonContainer.isHidden = !tribeData.showJoinButton
        contentView.backgroundColor = tribeData.showJoinButton ? UIColor.Sphinx.Body : UIColor.clear
        
        tribeNameLabel.text = tribeData.name
        tribeDescriptionTextView.text = tribeData.description

        loadImage(imageUrl: tribeData.imageUrl)
        
        removeDashedLineBorder()
        
        if tribeData.showJoinButton {
            addDashedLineBorder(
                color: bubble.direction.isIncoming() ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.SentMsgBG,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: tribeData.bubbleWidth,
                    height: kNewTribeBubbleHeight
                ),
                roundedBottom: tribeData.roundedBottom
            )
        }
    }
    
    func configurePreview(messageRow: TransactionMessageRow, delegate: LinkPreviewDelegate, doneCompletion: @escaping (Int) -> ()) {
        messageId = messageRow.transactionMessage.id
        
        if let link = messageRow.getMessageContent().stringFirstTribeLink {
            loadTribeDetails(link: link, completion: { tribeInfo in
                if let tribeInfo = tribeInfo {
                    messageRow.transactionMessage.tribeInfo = tribeInfo
                    doneCompletion(self.messageId)
                }
            })
        }
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
        configureColors(incoming: incoming)
    }
    
    func configureColors(incoming: Bool) {
        let color = incoming ? UIColor.Sphinx.SecondaryText : UIColor.Sphinx.SecondaryTextSent
        tribeDescriptionTextView.textColor = color
        tribeImageView.tintColor = color
        tribeImageView.layer.borderColor = color.resolvedCGColor(with: self)
        
        let buttonColor = incoming ? UIColor.Sphinx.LinkReceivedButtonColor : UIColor.Sphinx.LinkSentButtonColor
        tribeButtonView.backgroundColor = buttonColor
    }
    
    func loadImage(imageUrl: String?) {
        tribeImageView.sd_cancelCurrentImageLoad()
        
        if let image = imageUrl, let url = URL(string: image) {
            let transformer = SDImageResizingTransformer(
                size: tribeImageView.bounds.size,
                scaleMode: .aspectFill
            )
            
            tribeImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "tribePlaceholder"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    self.tribeImageView.image = (error == nil) ? image : UIImage(named: "tribePlaceholder")
                }
            )
        } else {
            tribeImageView.image = UIImage(named: "tribePlaceholder")
        }
    }
    
    func loadImage(tribeInfo: GroupsManager.TribeInfo?) {
        loadImage(imageUrl: tribeInfo?.img)
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
    
    @IBAction func seeTribeButtonTouched() {
        delegate?.didTapOnTribeButton()
    }
}
