//
//  KeyboardHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class KeyboardHelper {
    
    public static func getKeyboardAnimationDuration(notification: Notification) -> Double {
        var animationDuration:Double = 0.25
        if let number = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber {
            animationDuration = number.doubleValue
        }
        return animationDuration
    }
    
    public static func getKeyboardAnimationCurve(notification: Notification) -> Int {
        var animationCurve:Int = UIView.AnimationCurve.easeInOut.rawValue
        if let number = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationCurve = number.intValue
        }
        return animationCurve
    }
}
