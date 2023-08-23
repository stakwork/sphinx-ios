//
//  ThreadHeaderTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ThreadHeaderTableViewCellDelegate: class {
    func shouldExpandHeaderMessage()
    
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadGiphyDataFor(messageId: Int, and rowIndex: Int)
    
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
}

class ThreadHeaderTableViewCell: UITableViewCell {
    
    weak var delegate: ThreadHeaderTableViewCellDelegate!
    
    var rowIndex: Int!
    var messageId: Int?
    
    @IBOutlet weak var mediaMessageView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileDetailsView!
    @IBOutlet weak var messageContainer: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var senderAvatarView: ChatAvatarView!
    @IBOutlet weak var showMoreLabel: UILabel!
    @IBOutlet weak var showMoreContainer: UIView!
    @IBOutlet weak var bottomMarginView: UIView!
    @IBOutlet weak var differenceViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.clipsToBounds = false
        
        mediaMessageView.layer.cornerRadius = 9
        mediaMessageView.clipsToBounds = true
        
        fileDetailsView.layer.cornerRadius = 9
        fileDetailsView.clipsToBounds = true
        
        mediaMessageView.removeMargin()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func hideAllSubviews() {
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
        messageContainer.isHidden = true
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        isHeaderExpanded: Bool,
        delegate: ThreadHeaderTableViewCellDelegate,
        indexPath: IndexPath,
        headerDifference: CGFloat?
    ) {
        var mutableMessageCellState = messageCellState
        
        self.delegate = delegate
        self.rowIndex = indexPath.row
        self.messageId = mutableMessageCellState.messageId
        
        hideAllSubviews()
        
        configureWith(
            threadOriginalMessage: mutableMessageCellState.threadOriginalMessageHeader,
            isHeaderExpanded: isHeaderExpanded,
            headerDifference: headerDifference
        )
        
        configureWith(messageMedia: mutableMessageCellState.messageMedia, mediaData: mediaData)
        configureWith(genericFile: mutableMessageCellState.genericFile, mediaData: mediaData)
    }
    
    func configureWith(
        threadOriginalMessage: NoBubbleMessageLayoutState.ThreadOriginalMessage?,
        isHeaderExpanded: Bool,
        headerDifference: CGFloat?
    ) {
        guard let threadOriginalMessage = threadOriginalMessage else {
            return
        }
        
        if threadOriginalMessage.text.isNotEmpty {
            messageContainer.isHidden = false
        }
        
        messageLabel.text = threadOriginalMessage.text
        messageLabel.numberOfLines = isHeaderExpanded ? 0 : 12
        
        timestampLabel.text = threadOriginalMessage.timestamp
        senderNameLabel.text = threadOriginalMessage.senderAlias
        
        senderAvatarView.configureForUserWith(
            color: threadOriginalMessage.senderColor,
            alias: threadOriginalMessage.senderAlias,
            picture: threadOriginalMessage.senderPic
        )
        
        showMoreContainer.isHidden = !showMoreVisible(isHeaderExpanded)
        bottomMarginView.isHidden = !showMoreVisible(isHeaderExpanded)
        
        differenceViewHeightConstraint.constant = headerDifference ?? 0
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let messageMedia = messageMedia {
            
            mediaMessageView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                bubble: BubbleMessageLayoutState.Bubble(direction: .Incoming, grouping: .Isolated),
                and: self
            )
            
            mediaMessageView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    if messageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isGiphy {
                        self.delegate?.shouldLoadGiphyDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    }
                }
            }
        }
    }
    
    func configureWith(
        genericFile: BubbleMessageLayoutState.GenericFile?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let _ = genericFile {
            
            fileDetailsView.configureWith(
                mediaData: mediaData,
                and: self
            )
            
            fileDetailsView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadFileDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func showMoreVisible(
        _ isHeaderExpanded: Bool
    ) -> Bool {
        return !isHeaderExpanded && isLabelTruncated() && (messageLabel.text ?? "").isNotEmpty
    }
    
    lazy var labelHeight: CGFloat = {
        return UILabel.getTextSize(
            width: UIScreen.main.bounds.width - 32,
            text: messageLabel.text ?? "",
            font: messageLabel.font
        ).height
    }()

    
    func isLabelTruncated() -> Bool {
        guard let text = messageLabel.text, text.isNotEmpty else {
            return false
        }
        
        let maximumHeight: CGFloat = 240
        
        return labelHeight > maximumHeight
    }
    
    @IBAction func showMoreButtonTouched() {
        delegate?.shouldExpandHeaderMessage()
    }
}

extension ThreadHeaderTableViewCell : MediaMessageViewDelegate {
    func didTapMediaButton() {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func shouldLoadOriginalMessageMediaDataFrom(originalMessageMedia: BubbleMessageLayoutState.MessageMedia) {}
    func shouldLoadOriginalMessageFileDataFrom(originalMessageFile: BubbleMessageLayoutState.GenericFile) {}
}

extension ThreadHeaderTableViewCell : FileDetailsViewDelegate {
    func didTapDownloadButton() {
        if let messageId = messageId {
            delegate?.didTapFileDownloadButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
