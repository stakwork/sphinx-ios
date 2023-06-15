//
//  NewMessagesIndicatorView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol NewMessagesIndicatorViewDelegate : class {
    func didTouchButton()
}

class NewMessagesIndicatorView: UIView {
    
    weak var delegate: NewMessagesIndicatorViewDelegate?

    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("NewMessagesIndicatorView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        bubbleView.layer.cornerRadius = 5.0
        bubbleView.clipsToBounds = true
    }
    
    func configureWith(
        tableContentOffset: CGFloat,
        newMessagesCount: Int? = nil,
        andDelegate delegate: NewMessagesIndicatorViewDelegate? = nil
    ) {
        if let delegate = delegate {
            self.delegate = delegate
        }
        
        if let newMessagesCount = newMessagesCount {
            countLabel.text = "+\(newMessagesCount)"
            countLabel.isHidden = newMessagesCount == 0
        }
        
        self.isHidden = tableContentOffset < -10
    }

    @IBAction func buttonTouched() {
        delegate?.didTouchButton()
    }
}
