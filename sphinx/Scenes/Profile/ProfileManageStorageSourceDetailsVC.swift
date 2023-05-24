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
    @IBOutlet weak var mediaSourceTotalSizeLabel: UILabel!
    
    
    var source : StorageManagerMediaSource = .chats
    var totalSize : Double = 0.0
    
    lazy var vm : ProfileManageStorageSourceDetailsVM = {
        return ProfileManageStorageSourceDetailsVM(vc: self, tableView: mediaSourceDetailsTableView, source: self.source)
    }()
    
    static func instantiate(items:[StorageManagerItem],
                            source:StorageManagerMediaSource,
                            sourceTotalSize:Double)->ProfileManageStorageSourceDetailsVC{
        let viewController = StoryboardScene.Profile.profileManageStorageSourceDetailsVC.instantiate()
        viewController.source = source
        viewController.totalSize = sourceTotalSize
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
        mediaSourceTotalSizeLabel.text = formatBytes(Int(totalSize*1e6))
    }
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func deleteAllTapped(_ sender: Any) {
        print("deleteAllTapped")
    }
    
}
