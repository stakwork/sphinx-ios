//
//  AddressBookHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class AddressBookHeaderView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var letterLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("AddressBookHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        topView.addShadow(location: VerticalLocation.bottom, opacity: 0.2, radius: 5.0)
    }
    
    func configureView(letter: String) {
        letterLabel.text = letter
    }
}
