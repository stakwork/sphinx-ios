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
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint!
    var viewDidLayout : Bool = false
    
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.viewDidLayout = true
        })
        
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
    
    func animateHeader(shouldAppear:Bool){
        topContainerView.heightAnchor.constraint(equalToConstant: 100).isActive = false
        let newHeight = (shouldAppear) ? 100.0 : 0.0
        topContainerView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
        
        UIView.animate(withDuration: 0.2, delay: 0.0,options: .curveEaseIn ,animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func showErrorMessage(){
        AlertHelper.showAlert(title: "Error Retrieving Badge List", message: "")
    }
}
