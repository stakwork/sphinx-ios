//
//  NewChatViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewChatViewController: UIViewController {
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let windowInsets = getWindowInsets()
    
    static func instantiate() -> NewChatViewController {
        let viewController = StoryboardScene.Chat.newChatViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewChatViewController.keyboardWillShowHandler(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewChatViewController.keyboardWillHideHandler(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShowHandler(_ notification: Notification) {
        adjustContentForKeyboard(shown: true, notification: notification)
    }
    
    @objc func keyboardWillHideHandler(_ notification: Notification) {
        adjustContentForKeyboard(shown: false, notification: notification)
    }
    
    func adjustContentForKeyboard(shown: Bool, notification: Notification) {
        if var keyboardHeight = getKeyboardActualHeight(notification: notification) {
            
            let animationDuration:Double = KeyboardHelper.getKeyboardAnimationDuration(notification: notification)
            let animationCurve:Int = KeyboardHelper.getKeyboardAnimationCurve(notification: notification)
            
            print("KEYBOARD TOGGLE \(shown)")
            print("KEYBOARD HEIGHT \(keyboardHeight)")
            print("KEYBOARD TOGGLE \(shown)")
            
            self.bottomConstraint.constant = shown ? (keyboardHeight - windowInsets.bottom) : 0
            
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(animationCurve)),
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: { _ in

                }
            )
        }
    }
    
    func getKeyboardActualHeight(notification: Notification) -> CGFloat? {
        if let keyboardEndSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            return keyboardEndSize.height
        }
        return nil
    }

    @IBAction func dismissButtonTouched(_ sender: Any) {
        self.view.endEditing(true)
    }
}
