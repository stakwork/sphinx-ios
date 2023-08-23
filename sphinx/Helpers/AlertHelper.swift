//
//  AlertHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class AlertHelper {
    class func getRootVC() -> UIViewController? {
        if UIDevice.current.isIpad && UIApplication.shared.isSplitOrSlideOver {
            return UIApplication.shared.windows.first?.rootViewController
        } else {
            return UIApplication.shared.windows.last?.rootViewController
        }
    }
    
    class func showAlert(
        title: String,
        message: String,
        completion: (() -> ())? = nil
    ) {
        if let rootViewController: UIViewController = getRootVC() {
            showAlert(title: title, message: message, on: rootViewController, completion: completion)
        }
    }
    
    class func showAlert(
        title: String,
        message: String,
        on vc: UIViewController,
        additionAlertAction: UIAlertAction? = nil,
        completion: (() -> ())? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let additionAlertAction = additionAlertAction {
            alert.addAction(additionAlertAction)
        }
        let alertAction = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
            if let callback = completion {
                callback()
            }
        })
        alert.addAction(alertAction)
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func showTwoOptionsAlert(
        title: String,
        message: String,
        confirmButtonTitle: String? = nil,
        cancelButtonTitle: String? = nil,
        confirmStyle: UIAlertAction.Style = .default,
        cancelStyle: UIAlertAction.Style = .default,
        vc: UIViewController? = nil,
        confirm: (() -> ())? = nil,
        cancel: (() -> ())? = nil
    ){
        if let rootViewController: UIViewController = vc ?? getRootVC() {
            showTwoOptionsAlert(
                title: title,
                message: message,
                on: rootViewController,
                confirmButtonTitle: confirmButtonTitle,
                cancelButtonTitle: cancelButtonTitle,
                confirmStyle: confirmStyle,
                cancelStyle: cancelStyle,
                confirm: confirm,
                cancel: cancel
            )
        }
    }
    
    class func showTwoOptionsAlert(
        title: String,
        message: String,
        on vc: UIViewController,
        confirmButtonTitle: String? = nil,
        cancelButtonTitle: String? = nil,
        confirmStyle: UIAlertAction.Style = .default,
        cancelStyle: UIAlertAction.Style = .default,
        confirm: (() -> ())? = nil,
        cancel: (() -> ())? = nil
    ){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: cancelButtonTitle ?? "cancel".localized, style: cancelStyle , handler:{ (UIAlertAction)in
            if let cancel = cancel {
                cancel()
            }
        }))
        alert.addAction(UIAlertAction(title: confirmButtonTitle ?? "confirm".localized, style: confirmStyle , handler:{ (UIAlertAction)in
            if let confirm = confirm {
                confirm()
            }
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func showPromptAlert(
        title: String,
        message: String,
        textFieldText: String? = nil,
        secureEntry: Bool = false,
        on vc: UIViewController,
        confirm: ((String?) -> ())? = nil,
        cancel: (() -> ())? = nil
    ){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .destructive , handler:{ (UIAlertAction)in
            if let cancel = cancel {
                cancel()
            }
        }))
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .default , handler:{ (UIAlertAction)in
            if let confirm = confirm {
                if let textFields = alert.textFields, textFields.count > 0 {
                    confirm(
                        textFields[0].text
                    )
                } else {
                    confirm(nil)
                }
            }
        }))
        alert.addTextField(configurationHandler: { textField in
            textField.text = textFieldText
            textField.isSecureTextEntry = secureEntry
        })
        
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func showOptionsPopup(title: String,
                                message: String,
                                options: [String],
                                callbacks: [() -> ()],
                                sourceView: UIView,
                                vc: UIViewController? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        if options.count != callbacks.count {
            return
        }
        
        for x in 0..<options.count {
            let option = options[x]
            let callback = callbacks[x]
            
            alert.addAction(UIAlertAction(title: option, style: .default , handler: { (UIAlertAction) in
                callback()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler:{ (UIAlertAction) in }))
        
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceView.bounds
        
        if let viewController: UIViewController = vc ?? getRootVC() {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
