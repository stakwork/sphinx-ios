//
//  PopHandlerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class PopHandlerViewController: UIViewController {
    
    var popOnSwipeEnabled = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
}

extension PopHandlerViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let viewControllersCount = (navigationController?.viewControllers.count ?? 0)
        return (viewControllersCount > 1 && popOnSwipeEnabled) ? true : false
    }
}
