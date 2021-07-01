//
//  SubscriptionTimeIntervalView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SubscriptionTimeIntervalView : SubscriptionCommonView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var firstCheckbox: UILabel!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondCheckbox: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdCheckbox: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    
    enum Options: Int {
        case oneTime
        case makeEvery
    }
    
    override func setup() {
        Bundle.main.loadNibNamed("SubscriptionTimeIntervalView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.clipsToBounds = true
        
        checkboxesArray = [firstCheckbox, secondCheckbox, thirdCheckbox]
        labelsArray = [firstLabel, secondLabel, thirdLabel]
        
        shouldSelectOptionWithIndex(index: subscriptionManager.intervalIndexSelected)
    }
    
    func shouldSelectOptionWithIndex(index: Int?) {
        guard let index = index else {
            return
        }
        
        subscriptionManager.intervalIndexSelected = index
        super.selectOptionWithIndex(index: index, fontName: "Roboto-Medium", selectedLabelColor: UIColor.Sphinx.PrimaryText)
    }
    
    @IBAction func optionButtonTouched(_ sender: UIButton) {
        shouldSelectOptionWithIndex(index: sender.tag)
    }
}
