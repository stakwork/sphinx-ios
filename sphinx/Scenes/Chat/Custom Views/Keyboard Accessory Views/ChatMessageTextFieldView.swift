//
//  ChatMessageTextFieldView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ChatMessageTextFieldView: UIView {

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
        Bundle.main.loadNibNamed("ChatMessageTextFieldView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

}
