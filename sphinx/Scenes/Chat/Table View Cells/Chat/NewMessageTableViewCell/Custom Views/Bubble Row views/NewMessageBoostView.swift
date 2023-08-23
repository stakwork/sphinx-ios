//
//  NewMessageBoostView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewMessageBoostView: UIView {
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var boostIconView: UIView!
    @IBOutlet weak var boostIcon: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
    @IBOutlet weak var boostUserView1: MessageBoostImageView!
    @IBOutlet weak var boostUserView2: MessageBoostImageView!
    @IBOutlet weak var boostUserView3: MessageBoostImageView!
    
    @IBOutlet weak var boostUserCountLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("NewMessageBoostView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func resetViews() {
        boostUserView1.isHidden = true
        boostUserView2.isHidden = true
        boostUserView3.isHidden = true
    }
    
    func configureWith(
        boosts: BubbleMessageLayoutState.Boosts,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        resetViews()
        
        configureBoostIcon(active: bubble.direction.isOutgoing() || boosts.boostedByMe)
        configureWith(direction: bubble.direction)
        configureWith(boosts: boosts.boosts, and: bubble.direction)
        
        amountLabel.text = boosts.totalAmount.formattedWithSeparator
        
        let boostsCount = boosts.boosts.count
        boostUserCountLabel.isHidden = boostsCount <= 3
        boostUserCountLabel.text = "+\(boostsCount - 3)"
    }
    
    func configureWith(
        boosts: [BubbleMessageLayoutState.Boost],
        and direction: MessageTableCellState.MessageDirection
    ) {
        let nonDuplicatedBoosts = boosts.unique(selector: { $0.senderAlias == $1.senderAlias })
        
        if nonDuplicatedBoosts.count > 0 {
            boostUserView1.configureWith(boost: nonDuplicatedBoosts[0], and: direction)
        }
        
        if nonDuplicatedBoosts.count > 1 {
            boostUserView2.configureWith(boost: nonDuplicatedBoosts[1], and: direction)
        }
        
        if nonDuplicatedBoosts.count > 2 {
            boostUserView3.configureWith(boost: nonDuplicatedBoosts[2], and: direction)
        }
    }
    
    func configureBoostIcon(active: Bool) {
        boostIconView.backgroundColor = active ? UIColor.Sphinx.PrimaryGreen : UIColor.Sphinx.WashedOutReceivedText
        boostIcon.tintColor = active ? UIColor.white : UIColor.Sphinx.OldReceivedMsgBG
        boostIcon.tintColorDidChange()
    }
    
    func configureWith(direction: MessageTableCellState.MessageDirection) {
        let isIncoming = direction.isIncoming()
        
        unitLabel.textColor = isIncoming ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        boostUserCountLabel.textColor = isIncoming ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.WashedOutSentText
        
        let size: CGFloat = isIncoming ? 11 : 16
        amountLabel.font = UIFont(name: isIncoming ? "Roboto-Regular" : "Roboto-Medium", size: size)!
        unitLabel.font = UIFont(name: "Roboto-Regular", size: size)!
    }

}
