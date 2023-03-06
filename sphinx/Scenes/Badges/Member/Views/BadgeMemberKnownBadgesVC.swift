//
//  BadgeMemberKnownBadgesVC.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit
import Network

class BadgeMemberKnownBadgesVC : UIViewController{
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var noBadgesLabel: UILabel!
    
    var chatID: Int? = nil
    var badges : [Badge] = []
    private lazy var loadingViewController = LoadingViewController(backgroundColor: UIColor.clear)
    
    lazy var badgeMemberKnownBadgesVM : BadgeMemberKnownBadgesVM = {
        return BadgeMemberKnownBadgesVM(vc: self, tableView: tableView, chatID: chatID)
    }()
    
    static func instantiate(
        chatID:Int?,
        badges: [Badge]
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeMemberKnownBadgesVC.instantiate() as! BadgeMemberKnownBadgesVC
        viewController.chatID = chatID
        viewController.badges = badges
        
        return viewController
    }
    
    override func viewDidLoad() {
        viewTitle.textColor = UIColor.Sphinx.Text
        viewTitle.text = "badges.known-badges".localized
        noBadgesLabel.text = "badges.no-badges-message".localized
        navBarView.backgroundColor = UIColor.Sphinx.Body
        view.backgroundColor = UIColor.Sphinx.Body
        tableView.backgroundColor = UIColor.Sphinx.Body
        badgeMemberKnownBadgesVM.knownBadges = badges
        badgeMemberKnownBadgesVM.configureTable()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func addLoadingView(){
        addChildVC(
            child: loadingViewController,
            container: self.view
        )
    }
    
    func removeLoadingView(){
        self.removeChildVC(child: self.loadingViewController)
    }
}
