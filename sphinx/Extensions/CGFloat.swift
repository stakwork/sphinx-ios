//
//  CGFloat.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
    
    var finiteNonZero: CGFloat {
        get {
            if !self.isFinite || self < 0 {
                return CGFloat(0)
            }
            return self
        }
    }
}

extension Float {
    var speedDescription: String {
        get {
            if self == Float(Int(self)) {
                return "\(Int(self))"
            } else {
                return self.formattedWithDotDecimalSeparator
            }
        }
    }
}
