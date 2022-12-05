//
//  UIWindow.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension UIWindow {
    
    public enum Style: Int {
        case System
        case Dark
        case Light
    }
    
    func setStyle() {
        if #available(iOS 13.0, *) {
            if let userInterfaceStyle = UIWindow.getSavedStyle() {
                self.overrideUserInterfaceStyle = userInterfaceStyle
            } else {
                self.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    func setDarkStyle() {
        UserDefaults.Keys.appAppearence.set(UIWindow.Style.Dark.rawValue)
        setStyle()
    }
    
    public static func getSavedStyle() -> UIUserInterfaceStyle? {
        let style = UserDefaults.Keys.appAppearence.get(defaultValue: UIWindow.Style.System.rawValue)
        if style == UIWindow.Style.Dark.rawValue {
            return .dark
        } else if style == UIWindow.Style.Light.rawValue {
            return .light
        }
        return nil
    }
}
