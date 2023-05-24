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
    var isFirstLoad : Bool = true
    
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
        if(isFirstLoad == true){
            setupView()
            vm.finishSetup()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(isFirstLoad == false){
            setupView()
            vm.finishSetup()
        }
        isFirstLoad = false
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
        let itemDescription = (source == .chats) ? "chat media" : "podcasts"
        AlertHelper.showTwoOptionsAlert(
            title: "Are you sure?",
            message: "Proceeding will delete all of your \(itemDescription) from this device. This cannot be undone.",
            confirm: {
                switch(self.source){
                case .chats:
                    StorageManager.sharedManager.deleteAllImages(completion: {
                        self.handleReset()
                    })
                    break
                case .podcasts:
                    StorageManager.sharedManager.deleteAllAudioFiles(completion: {
                        self.handleReset()
                    })
                    break
                }
        })
    }
    
    func handleReset(){
        StorageManager.sharedManager.refreshAllStoredData {
            self.vm.finishSetup()
            self.totalSize = StorageManager.sharedManager.getItemGroupTotalSize(items: self.vm.getSourceItems())
            self.setupView()
            self.vm.tableView.reloadData()
        }
    }
    
    func showItemSpecificDetails(podcastFeed:PodcastFeed?,chat:Chat?,sourceType:StorageManagerMediaSource,items:[StorageManagerItem]){
        let vc = ProfileManageStorageSpecificChatOrContentFeedItemVC.instantiate(podcastFeed: podcastFeed, chat: chat, sourceType: sourceType,items: items)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
