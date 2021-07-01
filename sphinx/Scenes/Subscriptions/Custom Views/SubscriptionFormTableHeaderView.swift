//
//  SubscriptionFormTableHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SubscriptionFormTableHeaderView : UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("SubscriptionFormTableHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.clipsToBounds = true
        
        titleLabel.addTextSpacing(value: 2)
    }
    
    func configureLabel(text: String) {
        titleLabel.text = text
    }
}
