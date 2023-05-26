//
//  ProfileManageStorageSpecificChatOrContentFeedItem.swift
//  sphinx
//
//  Created by James Carucci on 5/24/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

protocol ProfileManageStorageSpecificChatOrContentFeedItemVCDelegate : NSObject{
    func finishedDeleteAll()
}

class ProfileManageStorageSpecificChatOrContentFeedItemVC : UIViewController{
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var totalSizeLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deletionSummaryView: UIView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var deletionSummaryCountLabel: UILabel!
    @IBOutlet weak var deletionSummarySizeLabel: UILabel!
    @IBOutlet weak var deletionSummaryButton: UIView!
    
    
    var sourceType : StorageManagerMediaSource = .chats
    var chat : Chat? = nil
    var podcastFeed: PodcastFeed? = nil
    var items : [StorageManagerItem] = []
    var delegate : ProfileManageStorageSpecificChatOrContentFeedItemVCDelegate? = nil
    var isFirstLoad:Bool = true
    
    lazy var vm : ProfileManageStorageSpecificChatOrContentFeedItemVM = {
        ProfileManageStorageSpecificChatOrContentFeedItemVM(vc: self, tableView: self.tableView,imageCollectionView: self.imageCollectionView, source: self.sourceType)
    }()
    
    static func instantiate(
        podcastFeed:PodcastFeed?,
        chat:Chat?,
        sourceType:StorageManagerMediaSource,
        items:[StorageManagerItem]
    )->ProfileManageStorageSpecificChatOrContentFeedItemVC{
        let viewController = StoryboardScene.Profile.profileManageStorageSpecificChatOrContentFeedItemVC.instantiate()
        viewController.sourceType = sourceType
        viewController.chat = chat
        viewController.podcastFeed = podcastFeed
        viewController.items = items
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewAndModels()
    }
    
    func setupViewAndModels(){
        
        if(isFirstLoad){
            vm.finishSetup(items: items)
            items = []
            isFirstLoad = false
        }
        
        if sourceType == .chats,
           let chat = chat{
            headerTitleLabel.text = chat.name
        }
        else if sourceType == .podcasts,
                let podcastFeed = podcastFeed{
            headerTitleLabel.text = podcastFeed.title
        }
        
        totalSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: vm.items) * 1e6))
        
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteAllTapped(_ sender: Any) {
        print("deleteAllTapped")
        let itemDescription = (sourceType == .chats) ? "chat.media".localized : "podcasts"
        AlertHelper.showTwoOptionsAlert(title: "are.you.sure".localized, message: "Confirming will delete all of your \(itemDescription). This cannot be undone.",confirm: {
            self.processDelete {
                //TODO update loading label here
                self.delegate?.finishedDeleteAll()
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    @IBAction func deletionSummaryCloseTap(_ sender: Any) {
        vm.selectedStatus = vm.items.map({_ in return false})
    }
    
    func updateDeletionSummaryLabel(){
        deletionSummaryButton.layer.cornerRadius = deletionSummaryButton.frame.height/2.0
        let count = vm.selectedStatus.filter({$0 == true}).count
        deletionSummaryCountLabel.text = "\(String(describing: count))"
        
        deletionSummarySizeLabel.text = formatBytes(Int(1e6 * vm.getSelectionSize()))
    }
    
    
    func processDelete(completion: @escaping ()->()){
        switch(self.sourceType){
        case .chats:
            
            break
        case .podcasts:
            if let pf = self.podcastFeed{
                let dlEpisodes = pf.episodes?.filter({$0.isDownloaded}) ?? []
                var podsCounter = dlEpisodes.count
                for episode in dlEpisodes{
                    episode.shouldDeleteFile(deleteCompletion: {
                        podsCounter -= 1
                        podsCounter > 0 ? () : (completion())
                    })
                }
            }
            break
        }
    }
    
}
