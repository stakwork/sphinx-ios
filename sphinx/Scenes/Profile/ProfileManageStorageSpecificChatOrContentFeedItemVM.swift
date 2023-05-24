//
//  ProfileManageStorageSpecificChatOrContentFeedItemVM.swift
//  sphinx
//
//  Created by James Carucci on 5/24/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageSpecificChatOrContentFeedItemVM : NSObject{
    
    var vc : ProfileManageStorageSpecificChatOrContentFeedItemVC
    var tableView : UITableView
    var items : [StorageManagerItem] = []
    
     init(vc:ProfileManageStorageSpecificChatOrContentFeedItemVC,tableView:UITableView) {
        self.vc = vc
        self.tableView = tableView
    }
    
    func finishSetup(items : [StorageManagerItem]){
        self.items = items
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
    }
    
    func getEpisodeForItem(item:StorageManagerItem)->PodcastEpisode?{
        if let itemID = item.uid,
           let cfi = FeedsManager.sharedInstance.fetchPodcastEpisode(itemID: itemID)
           {
            let episode = PodcastEpisode.convertFrom(contentFeedItem: cfi)
            return episode
        }
        
        return nil
    }
    
}


extension ProfileManageStorageSpecificChatOrContentFeedItemVM : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaStorageSourceTableViewCell.reuseID,
            for: indexPath
        ) as! MediaStorageSourceTableViewCell
        let item = items[indexPath.row]
        switch(vc.sourceType){
        case .podcasts:
            if let episode = getEpisodeForItem(item: item){
                cell.configure(podcastEpisode: episode, item: item, index: indexPath.row)
                cell.delegate = self
            }
            break
        case .chats:
            
            break
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Specify the desired height for your cells
        return 64.0 // Adjust this value according to your requirements
    }
    
}


extension ProfileManageStorageSpecificChatOrContentFeedItemVM : MediaStorageSourceTableViewCellDelegate{
    func didTapItemDelete(index: Int) {
        let item = items[index]
        AlertHelper.showTwoOptionsAlert(title: "Delete Episode?", message: "Are you sure you want to delete the episode? This action cannot be undone.",confirm: { [self] in
            if let sourcePath = item.sourceFilePath{
                StorageManager.sharedManager.deletePodsWithID(
                    fileName: sourcePath,
                    successCompletion: {
                        self.items.remove(at: index)
                        if self.items.count == 0{
                            StorageManager.sharedManager.refreshAllStoredData(completion: {
                                self.vc.navigationController?.popViewController(animated: true)
                                return
                            })
                        }
                        self.finishSetup(items: self.items)
                        self.vc.setupViewAndModels()
                        self.tableView.reloadData()
                    },
                    failureCompletion: {
                        AlertHelper.showAlert(title: "Error", message: "Could not delete the content. Please try again later.")
                    }
                )
            }
        })
    }
}
