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
    @IBOutlet weak var differenceViewHeightConstraint: NSLayoutConstraint!
    
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
        indexPath: IndexPath,
        headerDifference: CGFloat?
    ) {
        self.delegate = delegate
        
        var mutableMessageCellState = messageCellState
        
        if let threadOriginalMessage = mutableMessageCellState.threadOriginalMessageHeader {
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
        
        showMoreContainer.isHidden = !showMoreVisible(isHeaderExpanded)
        bottomMarginView.isHidden = !showMoreVisible(isHeaderExpanded)
        
        differenceViewHeightConstraint.constant = headerDifference ?? 0
    }
    
    func showMoreVisible(
        _ isHeaderExpanded: Bool
    ) -> Bool {
        return !isHeaderExpanded && isLabelTruncated() && !(messageLabel.text ?? "").isEmpty
    }
    
    lazy var labelHeight: CGFloat = {
        return UILabel.getTextSize(
            width: UIScreen.main.bounds.width - 32,
            text: messageLabel.text ?? "",
            font: messageLabel.font
        ).height
    }()

    
    func isLabelTruncated() -> Bool {
        guard let _ = messageLabel.text else {
            return false
        }
        
        let maximumHeight: CGFloat = 240
        
        return labelHeight > maximumHeight
    }
    
    static func getCellHeightWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?
    ) -> CGFloat {
        var mutableMessageCellState = messageCellState
        
        if let threadOriginalMessage = mutableMessageCellState.threadOriginalMessageHeader {
            let labelMargin: CGFloat = 32
            let bottomMarginViewHeight: CGFloat = 21
            let headerHeight: CGFloat = 36
            let maximumHeight: CGFloat = 240 ///12 lines
            
            var labelHeight = UILabel.getTextSize(
                width: UIScreen.main.bounds.width - labelMargin,
                text: threadOriginalMessage.text,
                font: UIFont(name: "Roboto-Regular", size: 17)!
            ).height
            
            let truncated = (labelHeight > maximumHeight)
            labelHeight = min(labelHeight, maximumHeight)
            labelHeight = truncated ? (labelHeight + bottomMarginViewHeight) : labelHeight
            
            return labelHeight + labelMargin + headerHeight
        }
        return 0.0
    }
    
    @IBAction func showMoreButtonTouched() {
        delegate?.shouldExpandHeaderMessage()
    }
}
