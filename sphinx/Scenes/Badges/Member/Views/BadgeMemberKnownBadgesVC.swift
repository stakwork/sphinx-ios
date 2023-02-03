//
//  BadgeMemberKnownBadgesVC.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class BadgeMemberKnownBadgesVC : UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    private var rootViewController: RootViewController!
    
    lazy var badgeMemberKnownBadgesVM : BadgeMemberKnownBadgesVM = {
        return BadgeMemberKnownBadgesVM(vc: self, tableView: tableView)
    }()
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeMemberKnownBadgesVC.instantiate() as! BadgeMemberKnownBadgesVC
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        badgeMemberKnownBadgesVM.configureTable()
    }
    
}
