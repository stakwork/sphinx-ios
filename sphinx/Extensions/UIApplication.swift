//
//  UIApplication.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else { return false }
        return !(window.frame.width == window.screen.bounds.width)
    }
    
    public func isActive() -> Bool {
        return self.applicationState == .active
    }
}
