//
//  StorageSummaryView.swift
//  sphinx
//
//  Created by James Carucci on 5/15/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ImportSeedViewDelegate : NSObject{
    func didTapCancel()
    func didTapConfirm()
}

class ImportSeedView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    var delegate : ImportSeedViewDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ImportSeedView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.backgroundColor = .clear
        
        confirmButton.layer.cornerRadius = confirmButton.frame.height/2.0
        cancelButton.layer.cornerRadius = cancelButton.frame.height/2.0
        contentView.layer.cornerRadius = 34.0
        textView.layer.cornerRadius = 4.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
           // self.summaryDict = self.getDebugValues()
        })
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.didTapCancel()
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        delegate?.didTapConfirm()
    }
}

