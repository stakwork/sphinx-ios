//
//  CommonPodcastBoostTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class CommonPodcastBoostTableViewCell : CommonChatTableViewCell {

    @IBOutlet weak var bubbleView: AudioBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var boostIconCircle: UIView!
    @IBOutlet weak var boostAmountLabel: UILabel!
    
    static let kBubbleHeight: CGFloat = 40.0
    static let kSentBubbleWidth: CGFloat = 152.0
    static let kReceivedBubbleWidth: CGFloat = 150.0
    static let kComposedBubbleMessageMargin: CGFloat = 2
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        boostIconCircle.layer.cornerRadius = boostIconCircle.frame.height / 2
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        self.configureRow(messageRow: messageRow, contact: contact, chat: chat)
        
        configureAmount()
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        lockSign.textColor = UIColor.Sphinx.WashedOutReceivedText
        lockSign.text = encrypted ? "lock" : ""
    }
    
    func configureAmount() {
        let amount = messageRow?.transactionMessage?.getBoostAmount() ?? 0
        boostAmountLabel.text = "\(amount)"
    }
    
    public static func getRowHeight() -> CGFloat {
        return kBubbleHeight + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin
    }
}
