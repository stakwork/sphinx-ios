//
//  TouchUpGestureRecognizer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 24/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass

class TouchUpGestureRecognizer: UIGestureRecognizer {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            self.state = .recognized
        }
    }
}
