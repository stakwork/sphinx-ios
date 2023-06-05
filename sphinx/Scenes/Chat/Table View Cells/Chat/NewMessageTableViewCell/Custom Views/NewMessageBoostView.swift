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

}
