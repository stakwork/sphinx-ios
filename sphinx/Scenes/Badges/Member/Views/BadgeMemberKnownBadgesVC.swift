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
    var chatID:Int? = nil
    private lazy var loadingViewController = LoadingViewController()
    
    lazy var badgeMemberKnownBadgesVM : BadgeMemberKnownBadgesVM = {
        return BadgeMemberKnownBadgesVM(vc: self, tableView: tableView, chatID: chatID)
    }()
    
    static func instantiate(
        rootViewController: RootViewController,
        chatID:Int?
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeMemberKnownBadgesVC.instantiate() as! BadgeMemberKnownBadgesVC
        viewController.rootViewController = rootViewController
        viewController.chatID = chatID
        
        return viewController
    }
    
    override func viewDidLoad() {
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
