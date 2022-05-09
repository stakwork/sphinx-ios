//
//  Library
//
//  Created by Tomas Timinskas on 08/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

@objc protocol MessageCellDelegate {
    @objc optional func didTapCancelButton(message: TransactionMessage)
    @objc optional func didTapAttachmentCancel(message: TransactionMessage)
    @objc optional func shouldReloadCell(cell: UITableViewCell)
    
    func didTapPayButton(message: TransactionMessage, cell: InvoiceReceivedTableViewCell)
    func didTapAttachmentRow(message: TransactionMessage)
    func shouldPlayVideo(url: URL?, data: Data?)
    func shouldStartCall(link: String, audioOnly: Bool)
    func didTapPayAttachment(message: TransactionMessage)
    func shouldReplayToMessage(message: TransactionMessage)
    func shouldScrollTo(message: TransactionMessage)
    func shouldScrollToBottom()
    func shouldGoBackToDashboard()
    func didTapOnPubKey(pubkey: String)
    func didTapAvatarView(message: TransactionMessage)
    func fileDownloadButtonTouched(message: TransactionMessage, data: Data, button: UIButton)
}

class CommonChatTableViewCell: SwipableReplyCell, RowWithLinkPreviewProtocol {
    
    var delegate: MessageCellDelegate?
    var audioDelegate: AudioCellDelegate?
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    @IBOutlet weak var rightLineContainer: UIView!
    @IBOutlet weak var leftLineContainer: UIView!
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    
    var boostedAmountView: MessageBoostView? = nil
    var linkPreviewView: LinkPreviewView? = nil
    var tribeLinkPreviewView: TribeLinkPreviewView? = nil
    var contactLinkPreviewView: ContactLinkPreviewView? = nil
    
    public static let kBubbleTopMargin: CGFloat = 21
    public static let kBubbleBottomMargin: CGFloat = 4
    public static let kRowHeaderHeight: CGFloat = 21
    
    public static let kMessageTextColor = UIColor.Sphinx.TextMessages
    public static let kEncryptionMessageColor = UIColor.Sphinx.PrimaryRed
    
    public static let kMinimumReceivedWidth:CGFloat = 220
    public static let kMinimumSentWidth:CGFloat = 200
    
    var messageRow: TransactionMessageRow?
    var contact: UserContact?
    var chat: Chat?
    
    var urlRanges = [NSRange]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func isDifferentRow(messageId: Int) -> Bool {
        return messageId != self.messageRow?.transactionMessage.id
    }
    
    func rowWillDisappear() {
        linkPreviewView?.stopLoading()
    }
    
    func configureRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        self.messageRow = messageRow
        self.contact = contact
        self.chat = chat
        
        addLongPressRescognizer()
    }
    
    static func getReplyTopPadding(message: TransactionMessage) -> CGFloat {
        return message.isReply() ? MessageReplyView.kMessageReplyHeight : 0
    }
    
    static func getMinimumWidth(message: TransactionMessage) -> CGFloat {
        if message.isBoosted() {
            return Constants.kReactionsMinimumWidth
        }
        
        if !message.isPaidAttachment() && !message.isReply() {
            return 0
        }
        
        if message.isIncoming() {
            return kMinimumReceivedWidth
        } else {
            return kMinimumSentWidth
        }
    }
    
    override func didSwipeToReplay() {
        PlayAudioHelper.playHaptic()
        
        if let message = messageRow?.transactionMessage {
            delegate?.shouldReplayToMessage(message: message)
        }
    }
    
    func commonConfigurationForMessages() {
        guard let messageRow = messageRow, let message = messageRow.transactionMessage else {
            return
        }
        
        addLinkPreview()
        addTribeLinkPreview()
        addPubKeyPreview()
        addBostedAmtLabel()
        
        let isPodcastLiveMessage = messageRow.isPodcastLive
        let consecutiveMessages = messageRow.getConsecutiveMessages()
        
        if let headerView = headerView {
            let shouldRemoveHeader = consecutiveMessages.previousMessage && !message.isFailedOrMediaExpired()
            headerView.isHidden = shouldRemoveHeader
            chatAvatarView?.isHidden = shouldRemoveHeader
            
            let topPading = CommonChatTableViewCell.getReplyTopPadding(message: message)
            topMarginConstraint.constant = (shouldRemoveHeader ? 0 : CommonChatTableViewCell.kRowHeaderHeight) + topPading
        }
        
        dateLabel.text = (messageRow.date ?? Date()).getStringDate(format: "hh:mm a")
        dateLabel.font = UIFont(name: "Roboto-Regular", size: 10.0)!
        
        chatAvatarView?.configureFor(messageRow: messageRow, contact: contact, chat: chat, with: self)

        rightLineContainer?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        leftLineContainer?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        if let senderLabel = senderLabel, let chat = chat {
            let isGroup = chat.isGroup()
            senderLabel.isHidden = !isGroup
            senderLabel.text = isGroup ? "\(message.getMessageSenderNickname()) " : ""
            senderLabel.textColor = ChatHelper.getSenderColorFor(message: message)
        }
        
        if isPodcastLiveMessage {
            hideHeaderElements()
        }
    }
    
    //Messages Boosts
    func addBostedAmtLabel() {
        func hideBoostedAmtLabel() {
            if let boostedView = boostedAmountView {
                boostedView.removeFromSuperview()
                boostedAmountView = nil
            }
        }
        
        hideBoostedAmtLabel()
        
        guard let bubbleView = getBubbbleView(), let messageRow = messageRow, let message = messageRow.transactionMessage, let reactions = message.reactions, (reactions.totalSats ?? 0) > 0 else {
            return
        }
        
        boostedAmountView = MessageBoostView(frame: CGRect(x: 0, y: 0, width: Constants.kReactionsMinimumWidth, height: Constants.kReactionsViewHeight))
        boostedAmountView?.configure(message: message)
        self.contentView.addSubview(boostedAmountView!)
        boostedAmountView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
    }
    
    
    //Link Previews
    func addLinkPreview() {
        func removeLinkPreviewView() {
            if let linkPreviewV = linkPreviewView {
                linkPreviewV.removeFromSuperview()
                linkPreviewView = nil
            }
        }
        
        if let bubbleView = getBubbbleView(), let messageRow = messageRow, messageRow.shouldLoadLinkPreview() {
            if linkPreviewView == nil {
                linkPreviewView = LinkPreviewView(frame: CGRect(x: 0, y: 0, width: Constants.kLinkBubbleMaxWidth, height: Constants.kLinkPreviewHeight))
            }
            
            let corners: UIRectCorner = messageRow.transactionMessage.consecutiveMessages.nextMessage ? [.bottomRight] : [.bottomLeft, .bottomRight]
            linkPreviewView?.roundCorners(corners: corners, radius: 10.0)
            linkPreviewView?.isHidden = true
            
            allContentView.addSubview(linkPreviewView!)
            linkPreviewView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
            
            linkPreviewView?.configurePreview(messageRow: messageRow, doneCompletion: { messageId in
                if (messageId != messageRow.transactionMessage.id || messageRow.transactionMessage.linkHasPreview) {
                    self.linkPreviewView?.isHidden = false
                    return
                }
                self.reloadRowOnLinkLoadFinished()
            })
        } else {
            removeLinkPreviewView()
        }
    }
    
    //Tribe Link Previews
    func addTribeLinkPreview() {
        func removeTribeLinkPreviewView() {
            if let tribeLinkPreviewV = tribeLinkPreviewView {
                tribeLinkPreviewV.removeFromSuperview()
                tribeLinkPreviewView = nil
            }
        }

        if let bubbleView = getBubbbleView(), let messageRow = messageRow, messageRow.shouldLoadTribeLinkPreview() {
            if tribeLinkPreviewView == nil {
                let linkHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
                tribeLinkPreviewView = TribeLinkPreviewView(frame: CGRect(x: 0, y: 0, width: Constants.kLinkBubbleMaxWidth, height: linkHeight))
                allContentView.addSubview(tribeLinkPreviewView!)
            }
            tribeLinkPreviewView?.isHidden = !messageRow.shouldShowTribeLinkPreview()
            
            if let tribeInfo = messageRow.transactionMessage.tribeInfo {
                tribeLinkPreviewView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
                tribeLinkPreviewView?.configureView(messageRow: messageRow, tribeInfo: tribeInfo, delegate: self)
                return
            }

            tribeLinkPreviewView?.configurePreview(messageRow: messageRow, delegate: self, doneCompletion: { messageId in
                if (messageId != messageRow.transactionMessage.id || messageRow.transactionMessage.linkHasPreview) {
                    return
                }
                self.reloadRowOnLinkLoadFinished()
            })
        } else {
            removeTribeLinkPreviewView()
        }
    }
    
    //PubKey Previews
    func addPubKeyPreview() {
        func removePubKeyPreviewView() {
            if let contactLinkPreviewV = contactLinkPreviewView {
                contactLinkPreviewV.removeFromSuperview()
                contactLinkPreviewView = nil
            }
        }

        if let bubbleView = getBubbbleView(), let messageRow = messageRow, messageRow.shouldShowPubkeyPreview() {
            messageRow.transactionMessage.linkHasPreview = true
            
            if contactLinkPreviewView == nil {
                let linkHeight = CommonChatTableViewCell.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
                contactLinkPreviewView = ContactLinkPreviewView(frame: CGRect(x: 0, y: 0, width: Constants.kLinkBubbleMaxWidth, height: linkHeight))
                allContentView.addSubview(contactLinkPreviewView!)
            }
            contactLinkPreviewView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
            contactLinkPreviewView?.configureView(messageRow: messageRow, delegate: self)
        } else {
            removePubKeyPreviewView()
        }
    }
    
    func reloadRowOnLinkLoadFinished() {
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            self.messageRow?.transactionMessage.linkHasPreview = true
            self.delegate?.shouldReloadCell?(cell: self)
            self.delegate?.shouldScrollToBottom()
        })
    }
    
    func getBubbbleView() -> UIView? {
        return nil
    }
    
    func hideHeaderElements() {
        for subview in headerView.subviews {
            subview.isHidden = true
        }
        senderLabel?.isHidden = false
        senderLabel?.backgroundColor = UIColor.clear
    }
    
    func addRightLine() {
        if let rightLineContainer = rightLineContainer {
            let y:CGFloat = (Int(contentView.frame.size.height) % 2 == 0) ? 2 : 1
            let lineFrame = CGRect(x: 0.0, y: y, width: 3, height: contentView.frame.size.height - y)
            let lineLayer = rightLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
            rightLineContainer.layer.addSublayer(lineLayer)
        }
    }
    
    func addLeftLine() {
        if let leftLineContainer = leftLineContainer {
            let y:CGFloat = (Int(contentView.frame.size.height) % 2 == 0) ? 2 : 1
            let lineFrame = CGRect(x: 0.0, y: y, width: 3, height: contentView.frame.size.height - y)
            let lineLayer = leftLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
            leftLineContainer.layer.addSublayer(lineLayer)
        }
    }
    
    //Links handling
    @objc func labelTapped(gesture: UITapGestureRecognizer) {
        if let label = gesture.view as? UILabel, let text = label.text {
            for range in urlRanges {
                if gesture.didTapAttributedTextInLabel(label, inRange: range) {
                    var link = (text as NSString).substring(with: range)
                    
                    if link.pubKeyMatches.count > 0 {
                        delegate?.didTapOnPubKey(pubkey: link)
                    } else if link.starts(with: "sphinx.chat://") {
                        if let url = URL(string: link), DeepLinksHandlerHelper.storeLinkQueryFrom(url: url) {
                            delegate?.shouldGoBackToDashboard()
                        }
                    } else if link.stringLinks.count > 0 {
                        if !link.contains("http") {
                            link = "http://\(link)"
                        }
                        UIApplication.shared.open(URL(string: link)!, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    func addLinksOnLabel(label: UILabel) {
        urlRanges = [NSRange]()
        urlRanges = label.addLinksOnLabel()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
        label.addGestureRecognizer(tap)
    }
    
    func addLongPressRescognizer() {
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        contentView.addGestureRecognizer(lpgr)
    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == .began) {
            if shouldPreventOtherGestures {
                return
            }
            highlightBubble()
        }
    }
    
    override func highlightBubble() {
        let bubbleLayers = getShapeLayers()
        
        var dataDict: [String: AnyObject] = [String: AnyObject]()
        dataDict["bubbleShapeLayers"] = bubbleLayers as AnyObject
        dataDict["tableCell"] = self as AnyObject
        
        if let messageId = self.messageRow?.getMessageId() {
            dataDict["messageId"] = messageId as AnyObject
        }
        NotificationCenter.default.post(name: .onMessageLongPressed, object: nil, userInfo: dataDict)
    }
    
    func getShapeLayers() -> [(CGRect, CAShapeLayer)] {
        let container = allContentView ?? contentView
        let viewsAndlayers = container.getShapeLayers(onSubviewsWithClasses: [CommonBubbleView.self, InvoiceContainerView.self, PaidAttachmentView.self], andTags: [CommonBubbleView.kBubbleLayerName, CommonBubbleView.kInvoiceDashedLayerName])
        return viewsAndlayers
    }
    
    public static func getLinkPreviewHeight(messageRow: TransactionMessageRow) -> CGFloat {
        if messageRow.shouldShowLinkPreview() {
            return Constants.kLinkPreviewHeight
        } else if messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview() {
            if messageRow.isJoinedTribeLink() || messageRow.isExistingContactPubkey().0 {
                return Constants.kTribeLinkPreviewHeight + Constants.kBubbleBottomMargin
            }
            return Constants.kTribeLinkPreviewHeight + Constants.kTribeLinkSeeButtonHeight + Constants.kBubbleBottomMargin
        }
        return 0
    }
    
    public static func getBubbleLinkPreviewHeight(messageRow: TransactionMessageRow) -> CGFloat {
        if messageRow.shouldShowLinkPreview() {
            return Constants.kLinkPreviewHeight
        }
        return 0
    }
}

extension CommonChatTableViewCell : LinkPreviewDelegate {
    func didTapOnTribeButton() {
        if let link = messageRow?.getMessageContent().stringFirstTribeLink, link.starts(with: "sphinx.chat://") {
            if let url = URL(string: link), DeepLinksHandlerHelper.storeLinkQueryFrom(url: url) {
                delegate?.shouldGoBackToDashboard()
            }
        }
    }
    
    func didTapOnContactButton() {
        if let link = messageRow?.getMessageContent().stringFirstPubKey {
            delegate?.didTapOnPubKey(pubkey: link)
        }
    }
}

extension CommonChatTableViewCell : ChatAvatarViewDelegate {
    func didTapAvatarView() {
        if let message = messageRow?.transactionMessage, (chat?.isPublicGroup() ?? false) {
            delegate?.didTapAvatarView(message: message)
        }
    }
}
