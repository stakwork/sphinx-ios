//
//  IntermitentAlphaAnimatedView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class IntermitentAlphaAnimatedView : UIView {
    var shouldAnimate = false
    
    func toggleAnimation(animate: Bool) {
        shouldAnimate = animate
        
        if animate {
            UIView.animate(withDuration: 0.7, animations: {
                self.alpha = 0.65
            }, completion: { _ in
                if self.shouldAnimate {
                    UIView.animate(withDuration: 0.7, animations: {
                        self.alpha = 1.0
                    }, completion: { _ in
                        if self.shouldAnimate {
                            self.toggleAnimation(animate: animate)
                        }
                    })
                }
            })
        }
    }
}
