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
}

class ThreadHeaderTableViewCell: UITableViewCell {
    
    weak var delegate: ThreadHeaderTableViewCellDelegate!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var senderAvatarView: ChatAvatarView!
    @IBOutlet weak var showMoreLabel: UILabel!
    @IBOutlet weak var showMoreContainer: UIView!
    @IBOutlet weak var bottomMarginView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        isHeaderExpanded: Bool,
        delegate: ThreadHeaderTableViewCellDelegate,
        indexPath: IndexPath
    ) {
        self.delegate = delegate
        
        var mutableMessageCellState = messageCellState
        
        if let threadOriginalMessage = mutableMessageCellState.threadOriginalMessage {
            messageLabel.text = threadOriginalMessage.text            
            messageLabel.numberOfLines = isHeaderExpanded ? 0 : 12
            
            timestampLabel.text = threadOriginalMessage.timestamp
            senderNameLabel.text = threadOriginalMessage.senderAlias
            
            senderAvatarView.configureForUserWith(
                color: threadOriginalMessage.senderColor,
                alias: threadOriginalMessage.senderAlias,
                picture: threadOriginalMessage.senderPic
            )
        }
        
        showMoreContainer.isHidden = isHeaderExpanded || !messageLabel.isTruncated
        bottomMarginView.isHidden = isHeaderExpanded || !messageLabel.isTruncated
    }
    
    static func getCellHeightWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?
    ) -> CGFloat {
        var mutableMessageCellState = messageCellState
        
        if let threadOriginalMessage = mutableMessageCellState.threadOriginalMessage {
            let labelHeight = UILabel.getLabelSize(
                width: UIScreen.main.bounds.width - (16 * 2),
                text: threadOriginalMessage.text,
                font: UIFont(name: "Roboto-Regular", size: 17)!
            ).height
            
            let labelMargin: CGFloat = 32
            let headerHeight: CGFloat = 36
            
            return labelHeight + labelMargin + headerHeight
        }
        return 0.0
    }
    
    @IBAction func showMoreButtonTouched() {
        delegate?.shouldExpandHeaderMessage()
    }
}
