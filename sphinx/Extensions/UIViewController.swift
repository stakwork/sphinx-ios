//
//  UIViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentNavigationControllerWith(vc: UIViewController) {
        let navigationController = UINavigationController()
        navigationController.viewControllers = [vc]
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overCurrentContext
        self.present(navigationController, animated: true)
    }
    
    func addChildVC(child: UIViewController, container: UIView) {
        addChild(child)
        child.view.frame = container.bounds
        container.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    
    func removeChildVC(child: UIViewController) {
        if let _ = child.parent {
            child.willMove(toParent: nil)
            child.removeFromParent()
            child.view.removeFromSuperview()
        }
    }
    
    func setStatusBarColor() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let rootVC = appDelegate.getRootViewController() else {
            return
        }
        rootVC.setStatusBar()
    }
}

extension UINavigationController {
    func pushOverRootVC(vc: UIViewController, animated: Bool = true) {
        var viewControllers = self.viewControllers
        
        if viewControllers.count == 1 {
            self.pushViewController(vc, animated: animated)
            return
        }
        
        viewControllers.removeLast()
        viewControllers.append(vc)
        self.setViewControllers(viewControllers, animated: animated)
    }
}
