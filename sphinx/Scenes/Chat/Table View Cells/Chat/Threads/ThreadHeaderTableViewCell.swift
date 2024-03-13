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
    func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int)
    
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int, isThreadOriginalMsg: Bool)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
    func didTapPlayPauseButtonFor(messageId: Int, and rowIndex: Int)
    
    func didTapOnLink(_ link: String)
    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect)
}

class ThreadHeaderTableViewCell: UITableViewCell {
    
    weak var delegate: ThreadHeaderTableViewCellDelegate!
    
    var rowIndex: Int!
    var messageId: Int?
    
    @IBOutlet weak var mediaMessageView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileDetailsView!
    @IBOutlet weak var audioMessageView: AudioMessageView!
    @IBOutlet weak var messageBoostView: NewMessageBoostView!
    @IBOutlet weak var messageContainer: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var senderAvatarView: ChatAvatarView!
    @IBOutlet weak var showMoreLabel: UILabel!
    @IBOutlet weak var showMoreContainer: UIView!
    @IBOutlet weak var bottomMarginView: UIView!
    @IBOutlet weak var differenceViewHeightConstraint: NSLayoutConstraint!
    
    var urlRanges = [NSRange]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.clipsToBounds = false
        
        mediaMessageView.layer.cornerRadius = 9
        mediaMessageView.clipsToBounds = true
        
        fileDetailsView.layer.cornerRadius = 9
        fileDetailsView.clipsToBounds = true
        
        audioMessageView.layer.cornerRadius = 9
        audioMessageView.clipsToBounds = true
        
        mediaMessageView.removeMargin()
        
        addLongPressRescognizer()
    }
    
    func addLongPressRescognizer() {
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        
        contentView.addGestureRecognizer(lpgr)
    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == .began) {
            didLongPressOnCell()
        }
    }
    
    func didLongPressOnCell() {
        if let messageId = messageId {
            
            let kMargin: CGFloat = 16
            let contentViewFrame = contentView.frame
            
            let frame = CGRect(
                x: contentViewFrame.origin.x,
                y: contentViewFrame.origin.y - kMargin,
                width: contentViewFrame.size.width,
                height: contentViewFrame.size.height - differenceViewHeightConstraint.constant + kMargin
            )
            
            delegate?.didLongPressOn(
                cell: self,
                with: messageId,
                bubbleViewRect: frame
            )
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func hideAllSubviews() {
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
        messageContainer.isHidden = true
        audioMessageView.isHidden = true
        messageBoostView.isHidden = true
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
        configureWith(audio: mutableMessageCellState.audio, mediaData: mediaData)
        
        if let bubble = mutableMessageCellState.bubble {
            configureWith(boosts: mutableMessageCellState.boosts, and: bubble)
        }
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
        
        addLinksToLabel(threadOriginalMessage: threadOriginalMessage)
        
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
    
    func addLinksToLabel(
        threadOriginalMessage: NoBubbleMessageLayoutState.ThreadOriginalMessage
    ) {
        urlRanges = []
        
        let font = UIFont(name: "Roboto-Regular", size: 17.0)!
        
        if threadOriginalMessage.linkMatches.isEmpty && threadOriginalMessage.highlightedMatches.isEmpty {
            messageLabel.attributedText = nil
            messageLabel.text = threadOriginalMessage.text
            messageLabel.font = font
        } else {
            let messageContent = threadOriginalMessage.text
            let attributedString = NSMutableAttributedString(string: messageContent)
            attributedString.addAttributes([NSAttributedString.Key.font: font], range: messageContent.nsRange)
            
            ///Highlighted text formatting
            let highlightedNsRanges = threadOriginalMessage.highlightedMatches.map {
                return $0.range
            }
            
            for (index, nsRange) in highlightedNsRanges.enumerated() {
                
                ///Subtracting the previous matches delimiter characters since they have been removed from the string
                let substractionNeeded = index * 2
                let adaptedRange = NSRange(location: nsRange.location - substractionNeeded, length: nsRange.length - 2)
                
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.foregroundColor: UIColor.Sphinx.HighlightedText,
                        NSAttributedString.Key.backgroundColor: UIColor.Sphinx.HighlightedTextBackground,
                        NSAttributedString.Key.font: threadOriginalMessage.highlightedFont
                    ],
                    range: adaptedRange
                )
            }
            
            ///Links formatting
            for match in threadOriginalMessage.linkMatches {
                
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.foregroundColor: UIColor.Sphinx.PrimaryBlue,
                        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                        NSAttributedString.Key.font: font
                    ],
                    range: match.range
                )
                
                urlRanges.append(match.range)
            }
            
            messageLabel.attributedText = attributedString
            messageLabel.isUserInteractionEnabled = true
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
        
        if urlRanges.isEmpty {
            messageLabel.removeGestureRecognizer(tap)
        } else {
            messageLabel.addGestureRecognizer(tap)
        }
        
        urlRanges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: urlRanges)
    }
    
    @objc func labelTapped(
        gesture: UITapGestureRecognizer
    ) {
        if let label = gesture.view as? UILabel, let text = label.text {
            for range in urlRanges {
                if gesture.didTapAttributedTextInLabel(
                    label,
                    inRange: range,
                    isThreadHeader: true
                ) {
                    let link = (text as NSString).substring(with: range)
                    delegate?.didTapOnLink(link)
                }
            }
        }
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let messageMedia = messageMedia {
            
            mediaMessageView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                isThreadOriginalMsg: false,
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
    
    func configureWith(
        audio: BubbleMessageLayoutState.Audio?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let audio = audio {
            
            audioMessageView.configureWith(
                audio: audio,
                mediaData: mediaData,
                isThreadOriginalMsg: false,
                bubble: BubbleMessageLayoutState.Bubble(direction: .Incoming, grouping: .Isolated),
                and: self
            )
            
            audioMessageView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadAudioDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        boosts: BubbleMessageLayoutState.Boosts?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let boosts = boosts {
            messageBoostView.configureWith(boosts: boosts, and: bubble)
            messageBoostView.isHidden = false
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
    func didTapMediaButton(isThreadOriginalMsg: Bool) {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: rowIndex, isThreadOriginalMsg: isThreadOriginalMsg)
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

extension ThreadHeaderTableViewCell : AudioMessageViewDelegate {
    func didTapPlayPauseButton(isThreadOriginalMsg: Bool) {
        if let messageId = messageId {
            delegate?.didTapPlayPauseButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func shouldLoadOriginalMessageAudioDataFrom(originalMessageAudio: BubbleMessageLayoutState.Audio) {}
}
