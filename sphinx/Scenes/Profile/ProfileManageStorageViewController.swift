//
//  ProfileManageStorageViewController.swift
//  sphinx
//
//  Created by James Carucci on 5/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageViewController : UIViewController{
    
    static func instantiate() -> ProfileManageStorageViewController {
        let viewController = StoryboardScene.Profile.profileManageStorageViewController.instantiate()
//        viewController.rootViewController = rootViewController
//        viewController.contactsService = rootViewController.contactsService
//        viewController.delegate = delegate
        
        return viewController
    }
}
