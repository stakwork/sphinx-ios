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
            headerTitleLabel.text = chat.getName()
        }
        else if sourceType == .podcasts,
                let podcastFeed = podcastFeed{
            headerTitleLabel.text = podcastFeed.title
        }
        
        totalSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: vm.items) * 1e6))
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDeleteSelected))
        deletionSummaryButton.addGestureRecognizer(gesture)
        
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func handleDeleteSelected(){
        AlertHelper.showTwoOptionsAlert(title: "are.you.sure".localized, message: "Confirming will delete the selected chat images from cache. This cannot be undone.",confirm: {
            self.processDeleteSelected {
                //TODO update loading label here
                
            }
        })
    }
    
    
    @IBAction func deleteAllTapped(_ sender: Any) {
        print("deleteAllTapped")
        let itemDescription = (sourceType == .chats) ? "chat.media".localized : "podcasts"
        AlertHelper.showTwoOptionsAlert(title: "are.you.sure".localized, message: "Confirming will delete all of your \(itemDescription). This cannot be undone.",confirm: {
            self.processDeleteAll {
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
    
    func processDeleteSelected(completion: @escaping ()->()){
        let cms = self.vm.getSelectedCachedMedia()
        StorageManager.sharedManager.deleteCacheItems(cms: cms, completion: {
            completion()
            self.vm.removeSelectedItems()
            if (self.vm.items.count == 0){
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    
    
    
    func processDeleteAll(completion: @escaping ()->()){
        switch(self.sourceType){
        case .chats:
            let dict = StorageManager.sharedManager.getItemDetailsByChat()
            if let chat = chat,
               let chatItems = dict[chat]{
                let cms = chatItems.compactMap({$0.cachedMedia})
                StorageManager.sharedManager.deleteCacheItems(cms: cms, completion: {
                    completion()
                })
            }
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
