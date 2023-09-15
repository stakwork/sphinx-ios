//
//  NewThreadOnlyMessageTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/18/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ThreadListTableViewCellDelegate: class {
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadGiphyDataFor(messageId: Int, and rowIndex: Int)
    func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int)
    
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
}

class ThreadListTableViewCell: UITableViewCell {
    
    weak var delegate: ThreadListTableViewCellDelegate!
    
    var rowIndex: Int!
    var messageId: Int?

    @IBOutlet weak var originalMessageAvatarView: ChatAvatarView!
    @IBOutlet weak var originalMessageSenderAliasLabel: UILabel!
    @IBOutlet weak var originalMessageDateLabel: UILabel!
    @IBOutlet weak var originalMessageTextLabel: UILabel!
    
    @IBOutlet weak var mediaMessageView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileDetailsView!
    @IBOutlet weak var audioMessageView: AudioMessageView!
    
    @IBOutlet weak var reply1Container: UIView!
    @IBOutlet weak var reply1AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply2Container: UIView!
    @IBOutlet weak var reply2AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply3Container: UIView!
    @IBOutlet weak var reply3AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply4Container: UIView!
    @IBOutlet weak var reply4AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply5Container: UIView!
    @IBOutlet weak var reply5AvatarView: ChatAvatarView!
    
    @IBOutlet weak var reply6Container: UIView!
    @IBOutlet weak var reply6AvatarView: ChatAvatarView!
    @IBOutlet weak var reply6CountContainer: UIView!
    @IBOutlet weak var reply6CountLabel: UILabel!
    
    @IBOutlet weak var repliesCountLabel: UILabel!
    @IBOutlet weak var lastReplyDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    func setupViews() {
        reply1Container.layer.cornerRadius = reply1Container.frame.height / 2
        reply2Container.layer.cornerRadius = reply2Container.frame.height / 2
        reply3Container.layer.cornerRadius = reply3Container.frame.height / 2
        reply4Container.layer.cornerRadius = reply4Container.frame.height / 2
        reply5Container.layer.cornerRadius = reply5Container.frame.height / 2
        reply6Container.layer.cornerRadius = reply6Container.frame.height / 2
        
        reply6CountContainer.layer.cornerRadius = reply6CountContainer.frame.height / 2
        
        reply1AvatarView.setInitialLabelSize(size: 12)
        reply2AvatarView.setInitialLabelSize(size: 12)
        reply3AvatarView.setInitialLabelSize(size: 12)
        reply4AvatarView.setInitialLabelSize(size: 12)
        reply5AvatarView.setInitialLabelSize(size: 12)
        reply6AvatarView.setInitialLabelSize(size: 12)
        
        mediaMessageView.layer.cornerRadius = 9
        mediaMessageView.clipsToBounds = true
        mediaMessageView.isUserInteractionEnabled = false
        mediaMessageView.removeMargin()
        
        fileDetailsView.layer.cornerRadius = 9
        fileDetailsView.clipsToBounds = true
        fileDetailsView.isUserInteractionEnabled = false
        
        audioMessageView.layer.cornerRadius = 9
        audioMessageView.clipsToBounds = true
        audioMessageView.isUserInteractionEnabled = false
    }
    
    func hideAllSubviews() {
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
        audioMessageView.isHidden = true
        originalMessageTextLabel.isHidden = true
    }
    
    func configureWith(
        threadCellState: ThreadTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        delegate: ThreadListTableViewCellDelegate?,
        indexPath: IndexPath
    ) {
        var mutableThreadCellState = threadCellState
        
        self.rowIndex = indexPath.row
        self.messageId = mutableThreadCellState.originalMessage?.id
        self.delegate = delegate
        
        hideAllSubviews()
        
        configureWith(threadLayoutState: mutableThreadCellState.threadMessagesState)
        configureWith(messageMedia: mutableThreadCellState.messageMedia, mediaData: mediaData)
        configureWith(genericFile: mutableThreadCellState.genericFile, mediaData: mediaData)
        configureWith(audio: mutableThreadCellState.audio, mediaData: mediaData)
    }
}
