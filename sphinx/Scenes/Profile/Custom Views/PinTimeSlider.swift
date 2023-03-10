//
//  PinTimeSlider.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PinTimeSlider: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var sliderControl: UISlider!
    @IBOutlet weak var hoursLabel: UILabel!
    
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
        Bundle.main.loadNibNamed("PinTimeSlider", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        sliderControl.maximumValue = Float(UserData.kMaximumPINHoursValue)
        
        let hours = userData.getPINHours()
        sliderControl.value = Float(hours)
        hoursLabel.text = getHoursLabel(hours)
    }
    
    func getHoursLabel(_ hours: Int) -> String {
        if hours == 0 {
            return "always.require.pin".localized
        }
        if hours == 1 {
            return "\(hours) \("hour".localized)"
        }
        if hours == 25{
            return "never.require.pin".localized
        }
        return "\(hours) \("hours".localized)"
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.value = roundf(sender.value)
        
        let intValue = Int(sender.value)
        hoursLabel.text = getHoursLabel(intValue)
        userData.setPINHours(hours: intValue)
    }
}
