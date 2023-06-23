//
//  SwipableReplyTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class SwipableReplyCell: UITableViewCell {
    
    @IBOutlet weak var allContentView: UIView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var button1: UIButton!
    
    var recognizer: UIPanGestureRecognizer?
    
    var panStartPoint: CGPoint?
    var startingRightLayoutConstraintConstant: CGFloat?
    
    var shouldPreventOtherGestures = false
    var isSwipeAllowed = true
    
    enum PanState: Int {
        case none, panningRow, scrollingTable
    }
    
    var buttonWidth: CGFloat = 40
    var panningState = PanState.none
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let _ = allContentView, let _ = leftConstraint, let _ = rightConstraint else {
            return
        }
        
        recognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipableCell.panAction(_:)))
        recognizer?.delegate = self
        allContentView?.addGestureRecognizer(recognizer!)
        
        hideButtons()
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return panningState != .panningRow
    }
    
    func resetButtonZIndex() {
        if button1 != nil { button1.superview!.sendSubviewToBack(button1)}
    }
    
    @objc func panAction(_ sender: UIPanGestureRecognizer) {
        if shouldPreventOtherGestures {
            return
        }
        
        if !isSwipeAllowed {
            return
        }
        
        guard let _ = allContentView, let _ = leftConstraint, let _ = rightConstraint else {
            return
        }
        
        switch(sender.state) {
        case UIGestureRecognizer.State.began:
            resetButtonZIndex()
            
            self.panningState = .none
            self.panStartPoint = recognizer!.translation(in: self.allContentView)
            self.startingRightLayoutConstraintConstant = self.rightConstraint.constant
        case UIGestureRecognizer.State.changed:
            let currentPoint = recognizer!.translation(in: self.allContentView)
            let deltaX = currentPoint.x - self.panStartPoint!.x
            let deltaY = currentPoint.y - self.panStartPoint!.y
            
            if panningState == .panningRow {
                if deltaY > deltaX && deltaY > 20 {
                    break
                } else {
                    if areButtonsHidden() {
                        self.showButtons()
                    }
                }
                
                var panningLeft = false
                if deltaX > 0 {
                    panningLeft = true
                }
                if startingRightLayoutConstraintConstant == 0 {
                    if panningLeft {
                        let constant = min(-deltaX, buttonWidth)
                        if constant == buttonWidth {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:false)
                        } else {
                            self.rightConstraint.constant = max(constant, 0)
                        }
                    } else {
                        let constant = max(-deltaX, 0)
                        if constant == 0 {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:false)
                        } else {
                            self.rightConstraint.constant = constant
                        }
                    }
                } else {
                    let adjustment = self.startingRightLayoutConstraintConstant! - deltaX
                    if panningLeft {
                        let constant = max(adjustment, 0)
                        if constant == 0 {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:false)
                        } else {
                            self.rightConstraint.constant = constant
                        }
                    } else {
                        let constant = min(adjustment, buttonWidth)
                        if constant == buttonWidth {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:false)
                        } else {
                            self.rightConstraint.constant = constant
                        }
                    }
                }
                self.leftConstraint.constant = -self.rightConstraint.constant
            }
            else if panningState == .none {
                if abs(deltaX) > 10 || abs(deltaY) > 10 {
                    if abs(deltaX) > abs(deltaY) {
                        panningState = .panningRow
                    }
                    else {
                        panningState = .scrollingTable
                    }
                }
            }
        case UIGestureRecognizer.State.ended:
            if panningState == .panningRow {
                panningState = .none
                if self.startingRightLayoutConstraintConstant == 0 {
                    let halfOfButtonOne = self.button1.frame.width / 2
                    if self.rightConstraint.constant >= halfOfButtonOne {
                        self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true)
                        
                        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true)
                            self.didSwipeToReplay()
                        })
                    } else {
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true)
                    }
                    
                    if self.rightConstraint.constant == 0 {
                        highlightBubble()
                    }
                }
            }
        case UIGestureRecognizer.State.cancelled:
            if panningState == .panningRow {
                panningState = .none
                if self.startingRightLayoutConstraintConstant == 0 {
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true)
                } else {
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true)
                }
            }
        default:
            break
        }
    }
    
    func updateConstraintsIfNeeded(_ animated: Bool, completion:@escaping (Bool)->()) {
        var duration = 0.0
        if (animated) {
            duration = 0.1
        }
        
        UIView.animate(withDuration: duration, animations: { () -> Void in
            self.layoutIfNeeded()
        }, completion: { (finished: Bool) -> Void in
            completion(finished)
        })
    }
    
    func resetConstraintContstantsToZero(_ animated: Bool, notifyDelegateDidClose: Bool) {
        guard let _ = allContentView, let _ = leftConstraint, let _ = rightConstraint else {
            return
        }
        
        resetButtonZIndex()
        
        if (self.startingRightLayoutConstraintConstant == 0 &&
            self.rightConstraint.constant == 0) {
            return
        }
        
        self.rightConstraint.constant = 0
        self.leftConstraint.constant = 0
        
        updateConstraintsIfNeeded(animated, completion: { (_) -> () in
            self.rightConstraint.constant = 0
            self.leftConstraint.constant = 0
            
            self.updateConstraintsIfNeeded(animated, completion: { (_) -> () in
                self.startingRightLayoutConstraintConstant = self.rightConstraint.constant
            })
        })
        
        hideButtons()
    }
    
    func setConstraintsToShowAllButtons(_ animated: Bool, notifyDelegateDidOpen: Bool) {
        guard let _ = allContentView, let _ = leftConstraint, let _ = rightConstraint else {
            return
        }
        
        bringButtonsToFront()
        
        if  self.startingRightLayoutConstraintConstant == buttonWidth &&
            self.rightConstraint.constant == buttonWidth {
            return
        }
        
        self.leftConstraint.constant = -self.buttonWidth
        self.rightConstraint.constant = self.buttonWidth
        
        self.updateConstraintsIfNeeded(true, completion: { (finished: Bool) -> () in
            
            self.leftConstraint.constant = -self.buttonWidth
            self.rightConstraint.constant = self.buttonWidth
            self.updateConstraintsIfNeeded(animated, completion: { (_) -> () in
                self.startingRightLayoutConstraintConstant = self.rightConstraint.constant
            })
        })
    }
    
    func bringButtonsToFront() {
        if button1 != nil { button1.superview!.bringSubviewToFront(button1)}
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetConstraintContstantsToZero(false, notifyDelegateDidClose: false)
    }
    
    func addFormConstraintsToFit(_ view: UIView, containerView: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraint(NSLayoutConstraint(item: view,
                                                       attribute: NSLayoutConstraint.Attribute.top,
                                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                                       toItem: containerView,
                                                       attribute: NSLayoutConstraint.Attribute.top,
                                                       multiplier: 1.0,
                                                       constant: 0.0))
        containerView.addConstraint(NSLayoutConstraint(item: view,
                                                       attribute: NSLayoutConstraint.Attribute.bottom,
                                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                                       toItem: containerView,
                                                       attribute: NSLayoutConstraint.Attribute.bottom,
                                                       multiplier: 1.0,
                                                       constant: 0.0))
        containerView.addConstraint(NSLayoutConstraint(item: view,
                                                       attribute: NSLayoutConstraint.Attribute.leading,
                                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                                       toItem: containerView,
                                                       attribute: NSLayoutConstraint.Attribute.leading,
                                                       multiplier: 1.0,
                                                       constant: 0.0))
        containerView.addConstraint(NSLayoutConstraint(item: view,
                                                       attribute: NSLayoutConstraint.Attribute.trailing,
                                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                                       toItem: containerView,
                                                       attribute: NSLayoutConstraint.Attribute.trailing,
                                                       multiplier: 1.0,
                                                       constant: 0.0))
    }
    
    func didSwipeToReplay() {}
    
    func highlightBubble() {}
    
    func areButtonsHidden() -> Bool {
        return self.button1?.isHidden ?? true
    }
    
    func hideButtons() {
        self.button1?.isHidden = true
    }
    
    func showButtons() {
        self.button1?.isHidden = false
    }
}
