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
    
    var contactsService = ContactsService()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return barStyle
    }
    
    func setStatusBarColor(light: Bool) {
        let darkMode =  traitCollection.userInterfaceStyle == .dark

        if #available(iOS 13.0, *) {
            barStyle = (light || darkMode) ? .lightContent : .darkContent
        } else {
            barStyle = light ? .lightContent : .default
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
        if let centerVC = getLastCenterViewController(), centerVC.isKind(of: ChatViewController.self) {
            return true
        }
        return false
    }
    
    func getChatVCId() -> Int? {
        if let centerVC = getLastCenterViewController() as? ChatViewController {
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
