//
//  BadgeManagementListVC.swift
//  sphinx
//
//  Created by James Carucci on 12/27/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit

class BadgeManagementListVC: UIViewController{
    private var rootViewController: RootViewController!
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeManagementListViewController.instantiate()
        //viewController.rootViewController = rootViewController
        
        return viewController
    }
}
