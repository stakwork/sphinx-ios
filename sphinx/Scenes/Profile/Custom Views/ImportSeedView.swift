//
//  StorageSummaryView.swift
//  sphinx
//
//  Created by James Carucci on 5/15/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ImportSeedView: UIView {

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
        Bundle.main.loadNibNamed("StorageSummaryView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.backgroundColor = .magenta
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
           // self.summaryDict = self.getDebugValues()
        })
    }
    
}

