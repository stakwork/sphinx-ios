//
//  UITextField.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/01/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

extension UITextField {
    func addDoneToolbar() {
            let onDone = (target: self, action: #selector(doneButtonTapped))

            let toolbar: UIToolbar = UIToolbar()
            toolbar.barStyle = .default
            toolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                UIBarButtonItem(title: "done".localized, style: .done, target: onDone.target, action: onDone.action)
            ]
            toolbar.sizeToFit()

            self.inputAccessoryView = toolbar
        }

        // Default actions:
        @objc func doneButtonTapped() { self.resignFirstResponder() }
}
