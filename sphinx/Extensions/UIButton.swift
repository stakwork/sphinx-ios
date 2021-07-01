//
//  UIButton.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.resolvedCGColor(with: self))
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func setBackgroundColor(color: UIColor, forUIControlState state: UIControl.State) {
        if let image = imageWithColor(color: color) {
            self.setBackgroundImage(image, for: state)
        }
    }
    
    func setTappedBackgroundColor(color: UIColor) {
        if let image = imageWithColor(color: color) {
            self.setBackgroundImage(image, for: .selected)
            self.setBackgroundImage(image, for: .highlighted)
            self.setBackgroundImage(image, for: .focused)
        }
    }
}
