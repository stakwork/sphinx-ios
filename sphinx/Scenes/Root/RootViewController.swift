//
//  Sphinx
//
//  Created by Tomas Timinskas on 21.01.18.
//  Copyright © 2018 Otto Suess. All rights reserved.
//

import UIKit
import KYDrawerController

class RootViewController: UIViewController, ContainerViewController {
    
    @IBOutlet weak var container: UIView?
    weak var currentViewController: UIViewController?
    var barStyle : UIStatusBarStyle = .lightContent
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return barStyle
    }
    
    func setStatusBar() {
        let darkMode =  traitCollection.userInterfaceStyle == .dark
        
        if #available(iOS 13.0, *) {
            barStyle = darkMode || isVCPresented() ? .lightContent : .darkContent
        } else {
            barStyle = darkMode || isVCPresented() ? .lightContent : .default
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func getLastCenterViewController() -> UIViewController? {
        if let drawerController = currentViewController as? KYDrawerController {
            if let centerVC = drawerController.mainViewController as? UINavigationController {
                if let lastCenterVC = centerVC.viewControllers.last {
                    return lastCenterVC
                }
            }
        }
        return nil
    }
    
    func getLeftMenuVC() -> LeftMenuViewController? {
        if let drawerController = currentViewController as? KYDrawerController {
            if let leftVC = drawerController.drawerViewController as? LeftMenuViewController {
                return leftVC
            }
        }
        return nil
    }
    
    func isChatVC() -> Bool {
        if let centerVC = getLastCenterViewController(), centerVC.isKind(of: NewChatViewController.self) {
            return true
        }
        return false
    }
    
    func isDashboardVC() -> Bool {
        if let centerVC = getLastCenterViewController(), centerVC.isKind(of: DashboardRootViewController.self) {
            return true
        }
        return false
    }
    
    func getChatVCId() -> Int? {
        if let centerVC = getLastCenterViewController() as? NewChatViewController {
            return centerVC.chat?.id
        }
        return nil
    }
    
    func isVCPresented() -> Bool {
        if let centerVC = getLastCenterViewController(), let _ = centerVC.presentedViewController {
            return true
        }
        return false
    }
}
