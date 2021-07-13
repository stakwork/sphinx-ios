//
//  LogarithmicSlider.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class LogarithmicSlider: UISlider {
    var _minimumValue: Float = 0
    var _maximumValue: Float = 0
    
    var sliderValue: Float {
        get {
            if(super.value == super.maximumValue) {
                return _maximumValue;
            }
            if(super.value == super.minimumValue) {
                return _minimumValue;
            }
            return expf(super.value)
        }
        set(value) {
            self.setSliderValue(value, animated: false)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let val = super.value
        _maximumValue = super.maximumValue
        super.maximumValue = logf(_maximumValue)
        _minimumValue = super.minimumValue
        super.minimumValue = logf(_minimumValue)
        self.sliderValue = val
    }
    
    func setSliderValue(_ value: Float, animated: Bool) {
        super.setValue(logf(value), animated: animated)
    }
}

class CustomSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let customBounds = CGRect(origin: self.frame.origin, size: CGSize(width: bounds.size.width, height: 5.0))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
