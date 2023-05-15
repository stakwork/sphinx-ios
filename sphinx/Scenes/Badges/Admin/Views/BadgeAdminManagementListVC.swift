//
//  BadgeManagementListVC.swift
//  sphinx
//
//  Created by James Carucci on 12/27/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit


class BadgeAdminManagementListVC: UIViewController{
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var badgeTableView: UITableView!
    @IBOutlet weak var badgeTemplateHeaderLabel: UILabel!
    
    var chatID:Int? = nil
    
    var badgeManagementListDataSource : BadgeAdminManagementListDataSource?
    
    static func instantiate(
        chatID:Int?
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeManagementListViewController.instantiate() as! BadgeAdminManagementListVC
        viewController.chatID = chatID
        
        return viewController
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.Sphinx.Body
        setupBadgeTable()
        badgeManagementListDataSource?.fetchTemplates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        badgeManagementListDataSource?.fetchBadges()
    }
    
    func setupBadgeTable(){
        viewTitle.textColor = UIColor.Sphinx.Text
        viewTitle.text = "badges.create-new-badge".localized
        navBarView.backgroundColor = UIColor.Sphinx.Body
        badgeTableView.backgroundColor = UIColor.Sphinx.Body
        badgeManagementListDataSource = BadgeAdminManagementListDataSource(vc: self,chatID: chatID)
        badgeManagementListDataSource?.setupDataSource()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func showBadgeDetail(
        badge: Badge,
        presentationContext: BadgeDetailPresentationContext
    ){
        let badgeDetailVC = BadgeAdminDetailVC.instantiate()
        if let valid_detailVC = badgeDetailVC as? BadgeAdminDetailVC{
            valid_detailVC.associatedBadge = badge
            valid_detailVC.presentationContext = presentationContext
        }
        self.navigationController?.pushViewController(badgeDetailVC, animated: true)
    }
    
    func showErrorMessage(){
        AlertHelper.showAlert(title: "Error Retrieving Badge List", message: "")
    }
}
