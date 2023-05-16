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
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var storageSummaryView: StorageSummaryView!
    var stats = [StorageManagerMediaType:Double]()
    
    static func instantiate(storageStats:[StorageManagerMediaType:Double]) -> ProfileManageStorageViewController {
        let viewController = StoryboardScene.Profile.profileManageStorageViewController.instantiate()
//        viewController.rootViewController = rootViewController
//        viewController.contactsService = rootViewController.contactsService
//        viewController.delegate = delegate
        viewController.stats = storageStats
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storageSummaryView.adjustBarWidths(dict: stats)
    }
    
    
    @IBAction func backButtonTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
