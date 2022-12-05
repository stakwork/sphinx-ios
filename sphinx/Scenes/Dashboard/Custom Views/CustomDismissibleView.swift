//
//  CustomDismissibleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/03/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class CustomDismissibleView : UIView, CAAnimationDelegate {
    
    var currentLocation: CGFloat = .zero
        
    var onViewDimissed: (() -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGesture()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGesture()
    }
    
    func addGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureEvent))
        addGestureRecognizer( panGesture )
    }
    
    @objc func panGestureEvent(panGesture: UIPanGestureRecognizer) {
        
        if panGesture.state == .began {
            reset()
            return
        }
        
        if panGesture.state == .changed {
            
            currentLocation = panGesture.translation(in: self).x
            
            var transform = CATransform3DIdentity
            transform = CATransform3DTranslate(transform, currentLocation, 0, 0)
            self.layer.transform = transform

            return
        }
        
        if panGesture.state == .ended {
            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.fromValue = NSNumber(floatLiteral: Double(currentLocation))
            
            if (abs(currentLocation) < self.frame.size.width / 2) {
                //Show
                currentLocation = 0
            } else {
                //Hide
                currentLocation = -self.frame.size.width
            }
            
            animation.toValue = NSNumber(floatLiteral: Double(currentLocation))
            
            animation.duration = TimeInterval(0.1)
            animation.repeatCount = 1
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.delegate = self
            
            self.layer.add(animation, forKey: "custom")
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag && currentLocation < 0 {
            onViewDimissed?()
        }
        reset()
    }
    
    func reset() {
        self.layer.transform = CATransform3DIdentity
        self.layer.removeAllAnimations()
    }
}
