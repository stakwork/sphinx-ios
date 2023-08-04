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
    @IBOutlet weak var arrowCircleView: UIView!
    @IBOutlet weak var countView: UIView!
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
        
        arrowCircleView.layer.cornerRadius = arrowCircleView.frame.height / 2
        arrowCircleView.clipsToBounds = true
        
        countView.layer.cornerRadius = countView.frame.height / 2
        countView.clipsToBounds = true
    }
    
    func configureWith(
        newMessagesCount: Int? = nil,
        hidden: Bool,
        andDelegate delegate: NewMessagesIndicatorViewDelegate? = nil
    ) {
        if let delegate = delegate {
            self.delegate = delegate
        }
        
        if let newMessagesCount = newMessagesCount {
            countLabel.text = "\(newMessagesCount)"
            countView.isHidden = newMessagesCount == 0
        }
        
        self.isHidden = hidden
    }

    @IBAction func buttonTouched() {
        delegate?.didTouchButton()
    }
}
