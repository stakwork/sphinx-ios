//
//  SwipableCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

/**
 * Swipable cell that allows up to 3 action buttons
 *
 * - author: Nikita Rodin
 * - version: 1.0
 */
class SwipableCell: UITableViewCell {
    
    @IBOutlet weak var allContentView: UIView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    var recognizer: UIPanGestureRecognizer?
    
    var panStartPoint: CGPoint?
    var startingRightLayoutConstraintConstant: CGFloat?
    
    let kBounceValue:CGFloat = 0.0
    enum CellUIState: Int {
        case oneButton, twoButtons, threeButtons
    }
    
    enum PanState: Int {
        case none, panningRow, scrollingTable
    }
    
    let COMPLETE_BUTTON_MARGIN = [
        CellUIState.twoButtons: CGFloat(10),
        CellUIState.threeButtons: CGFloat(54)
    ]
    let BUTTONS_WIDTH = [
        CellUIState.oneButton: CGFloat(87),
        CellUIState.twoButtons: CGFloat(87*2),
        CellUIState.threeButtons: CGFloat(87*3)
    ]
    
    // Buttons button1 and button3 are required. The horizontal order is: button 2, button3, button1
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    var isSwipeEnabled = true
    // State - is user moving a row, or scrolling a table
    var panningState = PanState.none
    
    var numberOfButtons = CellUIState.twoButtons
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        recognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipableCell.panAction(_:)))
        recognizer?.delegate = self
        self.allContentView.addGestureRecognizer(recognizer!)
        
        hideButtons()
    }
    
    // This is required to allow the recognizer to work with table scrolling
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow table scrolling if we recognized that user is not moving a row
        return panningState != .panningRow
    }
    
    /**
     Reset z-index of the buttons. Required to hide buttons under the cell background.
     */
    func resetButtonZIndex() {
        // Send buttons to back
        if button1 != nil { button1.superview!.sendSubviewToBack(button1)}
        if button2 != nil { button2.superview!.sendSubviewToBack(button2)}
        if button3 != nil { button3.superview!.sendSubviewToBack(button3)}
    }
    
    // Showing or hiding Action buttons
    @objc func panAction(_ sender: UIPanGestureRecognizer) {
        if !isSwipeEnabled {
            return
        }
        switch(sender.state) {
        case UIGestureRecognizer.State.began:
            
            // Send buttons under the background
            resetButtonZIndex()
            
            self.panningState = .none
            self.panStartPoint = recognizer!.translation(in: self.allContentView);
            self.startingRightLayoutConstraintConstant = self.rightConstraint.constant
        case UIGestureRecognizer.State.changed:
            let currentPoint = recognizer!.translation(in: self.allContentView);
            let deltaX = currentPoint.x - self.panStartPoint!.x;
            let deltaY = currentPoint.y - self.panStartPoint!.y;
            
            if panningState == .panningRow {
                // Check if we scrolling vertically
                if deltaY > deltaX && deltaY > 20 {
                    // Do not swipe
                    break // todo check correctness
                }
                else {
                    // Check if buttons are hidden.
                    if areButtonsHidden() {
                        self.showButtons()
                    }
                }
                
                var panningLeft = false
                if deltaX > 0 {
                    panningLeft = true
                }
                if startingRightLayoutConstraintConstant == 0 { // //The cell was closed and is now opening
                    if panningLeft {
                        let constant = min(-deltaX, self.buttonTotalWidth());
                        if constant == self.buttonTotalWidth() {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:false);
                        } else {
                            self.rightConstraint.constant = max(constant, 0);
                        }
                    }
                    else {  // Moving back to right, after it was started to left
                        let constant = max(-deltaX, 0)
                        if constant == 0 {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:false);
                        } else {
                            self.rightConstraint.constant = constant;
                        }
                    }
                }
                else {
                    //The cell was at least partially open.
                    let adjustment = self.startingRightLayoutConstraintConstant! - deltaX
                    if panningLeft {
                        let constant = max(adjustment, 0)
                        if constant == 0 {
                            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:false);
                        } else {
                            self.rightConstraint.constant = constant;
                        }
                    } else {
                        let constant = min(adjustment, self.buttonTotalWidth())
                        if constant == self.buttonTotalWidth() {
                            self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:false);
                        } else {
                            self.rightConstraint.constant = constant;
                        }
                    }
                }
                self.leftConstraint.constant = -self.rightConstraint.constant
            }
            else if panningState == .none {
                // Decide either user is scrolling the table or moving the row
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
                    //Cell was opening
                    let halfOfButtonOne = self.button1.frame.width / 2; //2
                    if self.rightConstraint.constant >= halfOfButtonOne { //3
                        //Open all the way
                        self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true);
                    } else {
                        //Re-close
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true);
                    }
                } else {
                    //Cell was closing
                    let buttonOnePlusHalfOfButton2 = self.button1.frame.width + (self.button3.frame.width / 2)
                    if self.rightConstraint.constant >= buttonOnePlusHalfOfButton2 {
                        //Re-open all the way
                        self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true);
                    } else {
                        //Close
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true);
                    }
                }
            }
        case UIGestureRecognizer.State.cancelled:
            if panningState == .panningRow {
                panningState = .none
                if self.startingRightLayoutConstraintConstant == 0 {
                    //Cell was closed - reset everything to 0
                    self.resetConstraintContstantsToZero(true, notifyDelegateDidClose:true);
                } else {
                    //Cell was open - reset to the open state
                    self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen:true);
                }
            }
        default:
            break;
        }
    }
    
    func updateConstraintsIfNeeded(_ animated: Bool, completion:@escaping (Bool)->()) {
        var duration = 0.0;
        if (animated) {
            duration = 0.1;
        }
        // Old style animation.
        UIView.animate(withDuration: duration, animations: { () -> Void in
            self.layoutIfNeeded();
        }, completion: { (finished: Bool) -> Void in
            completion(finished)
        })
    }
    
    
    /**
     Hide buttons
     */
    func resetConstraintContstantsToZero(_ animated: Bool, notifyDelegateDidClose: Bool) {
        
        resetButtonZIndex()
        
        if (self.startingRightLayoutConstraintConstant == 0 &&
            self.rightConstraint.constant == 0) {
            //Already all the way closed, no bounce necessary
            return;
        }
        
        self.rightConstraint.constant = -kBounceValue;
        self.leftConstraint.constant = kBounceValue;
        
        updateConstraintsIfNeeded(animated, completion: { (_) -> () in
            self.rightConstraint.constant = 0;
            self.leftConstraint.constant = 0;
            
            self.updateConstraintsIfNeeded(animated, completion: { (_) -> () in
                self.startingRightLayoutConstraintConstant = self.rightConstraint.constant;
            })
        })
        
        // Also hide buttons
        hideButtons()
    }
    
    /**
     Show buttons
     */
    func setConstraintsToShowAllButtons(_ animated: Bool, notifyDelegateDidOpen: Bool) {
        
        bringButtonsToFront()
        
        if  self.startingRightLayoutConstraintConstant == self.buttonTotalWidth() &&
            self.rightConstraint.constant == self.buttonTotalWidth() {
            return;
        }
        
        self.leftConstraint.constant = -self.buttonTotalWidth() - kBounceValue;
        self.rightConstraint.constant = self.buttonTotalWidth() + kBounceValue;
        
        self.updateConstraintsIfNeeded(true, completion: { (finished: Bool) -> () in
            
            self.leftConstraint.constant = -self.buttonTotalWidth();
            self.rightConstraint.constant = self.buttonTotalWidth();
            self.updateConstraintsIfNeeded(animated, completion: { (_) -> () in
                self.startingRightLayoutConstraintConstant = self.rightConstraint.constant
            })
        })
    }
    
    // Bring buttons to front to allow touches on them
    func bringButtonsToFront() {
        if button1 != nil { button1.superview!.bringSubviewToFront(button1)}
        if button2 != nil { button2.superview!.bringSubviewToFront(button2)}
        if button3 != nil { button3.superview!.bringSubviewToFront(button3)}
    }
    
    func buttonTotalWidth() -> CGFloat {
        return BUTTONS_WIDTH[numberOfButtons]!
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetConstraintContstantsToZero(false, notifyDelegateDidClose: false)
    }
    
    // MARK: Button actions
    @IBAction func complemedButtonAction(_ sender: AnyObject) {
        button2Action()
    }
    
    @IBAction func canceledButtonAction(_ sender: AnyObject) {
        button1Action()
    }
    
    // Shows popover with date picker.
    @IBAction func bellButtonAction(_ sender: AnyObject) {
        button3Action()
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
    
    // MARK: Methods to override
    
    func button1Action() {}
    func button2Action() {}
    func button3Action() {}
    
    func areButtonsHidden() -> Bool {
        return self.button1.isHidden
    }
    
    func hideButtons() {
        if button1 != nil { self.button1.isHidden = true }
        if button3 != nil { self.button3.isHidden = true }
    }
    
    func showButtons() {
        self.button1.isHidden = false
        self.button3.isHidden = false
    }
    
    // Returns prefered height of the inner content when expanded
    func getPreferedHeight() -> CGFloat {
        return 300
    }
    
    func setFormOpened(_ isOpened: Bool) {
    }
}
