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
    
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var badgeTableView: UITableView!
    
    private var rootViewController: RootViewController!
    var badgeManagementListDataSource : BadgeManagementListDataSource?
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeManagementListViewController.instantiate() as! BadgeManagementListVC
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        setupBadgeTable()
    }
    
    func setupBadgeTable(){
        topContainerView.backgroundColor = UIColor.Sphinx.Body
        viewTitle.textColor = UIColor.Sphinx.Text
        navBarView.backgroundColor = UIColor.Sphinx.Body
        badgeManagementListDataSource = BadgeManagementListDataSource(vc: self)
        badgeManagementListDataSource?.setupDataSource()
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func showBadgeDetail(badge:Badge){
        let badgeDetailVC = BadgeDetailVC.instantiate(rootViewController: rootViewController)
        if let valid_detailVC = badgeDetailVC as? BadgeDetailVC{
            valid_detailVC.associatedBadge = badge
        }
        self.navigationController?.pushViewController(badgeDetailVC, animated: true)
    }
}
