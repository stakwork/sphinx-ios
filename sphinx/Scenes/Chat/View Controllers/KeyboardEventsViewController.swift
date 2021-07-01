//
//  KeyboardEventsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class KeyboardEventsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardEventsViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardEventsViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        
    }
}
