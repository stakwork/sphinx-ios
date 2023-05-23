//
//  ProfileManageStorageSourceDetailsVC.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageSourceDetailsVC : UIViewController{
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var mediaSourceDetailsTableView: UITableView!
    
    var source : StorageMediaManagerSource = .chats
    
    lazy var vm : ProfileManageStorageSourceDetailsVM = {
        return ProfileManageStorageSourceDetailsVM(vc: self, tableView: mediaSourceDetailsTableView)
    }()
    
    static func instantiate(items:[StorageManagerItem],source:StorageMediaManagerSource)->ProfileManageStorageSourceDetailsVC{
        let viewController = StoryboardScene.Profile.profileManageStorageSourceDetailsVC.instantiate()
        viewController.source = source
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //view.backgroundColor = .magenta
        setupView()
        vm.finishSetup()
    }
    
    func setupView(){
        switch(source){
        case .chats:
            headerLabel.text = "Chats"
            break
        case .podcasts:
            headerLabel.text = "Podcasts"
            break
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
