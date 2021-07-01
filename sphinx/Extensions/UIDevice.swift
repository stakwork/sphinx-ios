//
//  UIDevice.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension UIDevice {
    
    var isIpad: Bool {
        get {
            return self.userInterfaceIdiom == .pad
        }
    }
}
