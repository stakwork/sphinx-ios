//
//  NewChatKeyboardHandlerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewKeyboardHandlerViewController: PopHandlerViewController {
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let windowInsets = getWindowInsets()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeKeyboardObservers()
    }
    
    func addKeyboardObservers() {
        removeKeyboardObservers()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NewKeyboardHandlerViewController.keyboardWillShowHandler(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NewKeyboardHandlerViewController.keyboardWillHideHandler(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillShowHandler(_ notification: Notification) {
        adjustContentForKeyboard(shown: true, notification: notification)
    }
    
    @objc func keyboardWillHideHandler(_ notification: Notification) {
        adjustContentForKeyboard(shown: false, notification: notification)
    }
    
    func adjustContentForKeyboard(shown: Bool, notification: Notification) {
        if let keyboardHeight = getKeyboardActualHeight(notification: notification) {
            
            let animationDuration:Double = KeyboardHelper.getKeyboardAnimationDuration(notification: notification)
            let animationCurve:Int = KeyboardHelper.getKeyboardAnimationCurve(notification: notification)
            
            self.bottomConstraint.constant = shown ? (keyboardHeight - windowInsets.bottom) : 0
            
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(animationCurve)),
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                    self.didToggleKeyboard()
                }
            )
        }
    }
    
    func didToggleKeyboard() {}
    
    func isKeyboardVisible() -> Bool {
        return bottomConstraint.constant > 0
    }
    
    func getKeyboardActualHeight(notification: Notification) -> CGFloat? {
        if let keyboardEndSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            return keyboardEndSize.height
        }
        return nil
    }
    
}
