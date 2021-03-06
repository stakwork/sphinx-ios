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
    
    class func showAlert(title: String, message: String, completion: (() -> ())? = nil) {
        if let rootViewController: UIViewController = getRootVC() {
            showAlert(title: title, message: message, on: rootViewController, completion: completion)
        }
    }
    
    class func showAlert(title: String, message: String, on vc: UIViewController, completion: (() -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
            if let callback = completion {
                callback()
            }
        })
        alert.addAction(alertAction)
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func showTwoOptionsAlert(title: String, message: String, confirm: (() -> ())? = nil, cancel: (() -> ())? = nil){
        if let rootViewController: UIViewController = getRootVC() {
            showTwoOptionsAlert(title: title, message: message, on: rootViewController, confirm: confirm, cancel: cancel)
        }
    }
    
    class func showTwoOptionsAlert(title: String, message: String, on vc: UIViewController, confirm: (() -> ())? = nil, cancel: (() -> ())? = nil){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .destructive , handler:{ (UIAlertAction)in
            if let cancel = cancel {
                cancel()
            }
        }))
        alert.addAction(UIAlertAction(title: "confirm".localized, style: .default , handler:{ (UIAlertAction)in
            if let confirm = confirm {
                confirm()
            }
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    class func showOptionsPopup(title: String,
                                message: String,
                                options: [String],
                                callbacks: [() -> ()],
                                sourceView: UIView) {
        
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
        
        if let rootViewController: UIViewController = getRootVC() {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }
}
