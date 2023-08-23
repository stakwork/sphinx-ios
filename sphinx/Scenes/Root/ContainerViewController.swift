//
//  Sphinx
//
//  Created by Tomas Timinskas on 21.01.18.
//  Copyright © 2018 Otto Suess. All rights reserved.
//

import UIKit
import KYDrawerController

public protocol ContainerViewController: class {
    var container: UIView? { get }
    var currentViewController: UIViewController? { get set }
    func setContainerContent(_ viewController: UIViewController)
}

public extension ContainerViewController where Self: UIViewController {
    
    func setContainerContent(_ viewController: UIViewController) {
        if self.currentViewController == nil {
            self.setInitialViewController(viewController)
        } else {
            self.switchToViewController(viewController)
        }
    }
    
    func setInitialViewController(_ viewController: UIViewController) {
        guard let container = container else {
            return
        }
        
        addChild(viewController)
        viewController.view.frame = container.bounds
        container.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        currentViewController = viewController
    }
    
    func switchToViewController(_ viewController: UIViewController, completion: (() -> Void)? = nil) {
        guard let currentViewController = currentViewController, let container = container else {
            setInitialViewController(viewController)
            return
        }
        
        currentViewController.willMove(toParent: nil)
        addChild(viewController)
        currentViewController.view.layer.zPosition = 1
        viewController.view.frame = container.bounds
        viewController.view.isUserInteractionEnabled = false
        
        transition(from: currentViewController,
                   to: viewController,
                   duration: 0.0,
                   options: [],
                   animations: { [currentViewController] in
                    currentViewController.view.alpha = 0
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                currentViewController.view.removeFromSuperview()
                currentViewController.removeFromParent()
                viewController.didMove(toParent: self)
                self.currentViewController = viewController
                viewController.view.isUserInteractionEnabled = true
                completion?()
        })
    }
    
    func attemptClosingLeftMenu() {
        if let currentVC =  currentViewController as? KYDrawerController {
            currentVC.setDrawerState(KYDrawerController.DrawerState.closed, animated: false)
        }
    }
    
    func getDrawer() -> KYDrawerController? {
        if let drawer =  currentViewController as? KYDrawerController {
            return drawer
        }
        return nil
    }
    
    func getCenterNavigationController() -> UINavigationController? {
        if let drawer = getDrawer(),
            let centerNV = drawer.mainViewController as? UINavigationController {
                return centerNV
        }
        return nil
    }
    
    func setCenterViewController(vc: UIViewController) {
        if let drawer = getDrawer(),
            let centerVC = drawer.mainViewController as? UINavigationController,
            let lastVC = centerVC.viewControllers.last {
            
                if object_getClass(vc) == object_getClass(lastVC) {
                    return
                }
        }
        
        setCenterViewControllers(vcs: [vc])
    }
    
    func setCenterViewControllers(vcs: [UIViewController]) {
        if let drawer =  currentViewController as? KYDrawerController, let navigationController =  drawer.mainViewController as? UINavigationController {
            navigationController.viewControllers = vcs
        }
    }
    
    func presentViewController(vc: UIViewController) {
        if let drawer =  currentViewController as? KYDrawerController, let navigationController =  drawer.mainViewController as? UINavigationController {
            navigationController.present(vc, animated: true, completion: nil)
        }
    }
}
