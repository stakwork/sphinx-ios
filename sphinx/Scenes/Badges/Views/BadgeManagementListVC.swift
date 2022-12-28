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
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var badgeTableView: UITableView!
    
    private var rootViewController: RootViewController!
    var badgeManagementListDataSource : BadgeManagementListDataSource?
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeManagementListViewController.instantiate()
        //viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        setupBadgeTable()
    }
    
    func setupBadgeTable(){
        badgeManagementListDataSource = BadgeManagementListDataSource(vc: self)
        badgeManagementListDataSource?.setupDataSource()
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
