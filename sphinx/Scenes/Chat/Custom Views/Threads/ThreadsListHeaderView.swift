//
//  ThreadsListHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ThreadsListHeaderView: UIView {
    
    var delegate : ThreadHeaderViewDelegate? = nil
    
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
        Bundle.main.loadNibNamed("ThreadsListHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func setDelegate(
        _ delegate: ThreadHeaderViewDelegate?
    ) {
        self.delegate = delegate
    }
    
    @IBAction func backButtonTouched() {
        delegate?.didTapBackButton()
    }
    
}
