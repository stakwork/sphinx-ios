//
//  MaxMemorySlider.swift
//  sphinx
//
//  Created by James Carucci on 5/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MaxMemorySlider: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var sliderControl: UISlider!
    @IBOutlet weak var maxMemoryLabel: UILabel!
    
    let userData = UserData.sharedInstance
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MaxMemorySlider", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        sliderControl.maximumValue = Float(UserData.kMaximumMemoryFootprint)
        
        let gb = userData.getMaxMemory()
        sliderControl.value = Float(gb)
        maxMemoryLabel.text = getMaxGBLabel(gb)
    }
    
    func getMaxGBLabel(_ gb: Int) -> String {
        return "\(gb) GB"
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.value = roundf(sender.value)
        
        let intValue = Int(sender.value)
        maxMemoryLabel.text = getMaxGBLabel(intValue)
        userData.setMaxMemory(GB: intValue)
    }
}
