//
//  UISegmentedControl.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension UISegmentedControl {
    func setLayout(tintColor: UIColor) {
        if #available(iOS 13, *) {
            let background = UIImage(color: .clear, size: CGSize(width: 2, height: 30))
            let divider = UIImage(color: tintColor, size: CGSize(width: 2, height: 30))
            self.setBackgroundImage(background, for: .normal, barMetrics: .default)
            self.setBackgroundImage(divider, for: .selected, barMetrics: .default)
            self.setDividerImage(divider, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
            self.layer.borderWidth = 2
            self.layer.borderColor = tintColor.cgColor
            self.setTitleTextAttributes([.foregroundColor: tintColor], for: .normal)
            self.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        } else {
            self.tintColor = tintColor
        }
    }
}
