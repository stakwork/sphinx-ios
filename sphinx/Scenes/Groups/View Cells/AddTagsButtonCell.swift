//
//  AddTagsButtonCell.swift
//  sphinx
//
//  Created by Oko-osi Korede on 22/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import UIKit

class AddTagsButtonCell: UICollectionReusableView {
    static let reuseIdentifier = "AddTagsButtonCell"
    @IBOutlet var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("AddTagsButtonCell", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

