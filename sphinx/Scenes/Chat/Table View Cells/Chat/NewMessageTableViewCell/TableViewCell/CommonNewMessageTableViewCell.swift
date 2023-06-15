//
//  CommonNewMessageTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class CommonNewMessageTableViewCell : SwipableReplyCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addLongPressRescognizer()
    }
    
    
    func addLongPressRescognizer() {
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        
        contentView.addGestureRecognizer(lpgr)
    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == .began) {
            if shouldPreventOtherGestures {
                return
            }
            didLongPressOnCell()
        }
    }
    
    func didLongPressOnCell() {}
}
