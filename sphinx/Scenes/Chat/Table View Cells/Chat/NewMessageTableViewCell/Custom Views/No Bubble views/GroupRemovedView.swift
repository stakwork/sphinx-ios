//
//  GroupRemovedView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class GroupRemovedView: UIView {
    
    weak var delegate: GroupActionsViewDelegate?
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("GroupRemovedView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        messageView.layer.cornerRadius = 8
        messageView.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        messageView.layer.borderWidth = 1
        
        deleteButton.layer.cornerRadius = 5
    }
    
    func configureWith(
        message: String,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        self.delegate = delegate
        
        messageLabel.text = message
    }
    
    @IBAction func deleteButtonTouched() {
        delegate?.didTapDeleteTribeButton()
    }
}
