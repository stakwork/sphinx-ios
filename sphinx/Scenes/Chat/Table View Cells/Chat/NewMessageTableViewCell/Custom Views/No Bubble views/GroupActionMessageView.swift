//
//  GroupActionMessageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class GroupActionMessageView: UIView {

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("GroupActionMessageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        messageView.layer.cornerRadius = messageView.bounds.height / 2
        messageView.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        messageView.layer.borderWidth = 1
    }
    
    func configureWith(
        message: String
    ) {
        messageLabel.text = message
    }

}
