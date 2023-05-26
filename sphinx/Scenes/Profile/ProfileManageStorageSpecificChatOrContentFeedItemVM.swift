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
    var imageCollectionView : UICollectionView
    var items : [StorageManagerItem] = []{
        didSet{
            selectedStatus = items.map({_ in return false})
        }
    }
    var selectedStatus : [Bool] = []{
        didSet{
            vc.deletionSummaryView.isHidden = (getIsSelectingImages()) ? false : true
            vc.view.bringSubviewToFront(vc.deletionSummaryView)
            vc.updateDeletionSummaryLabel()
            imageCollectionView.reloadData()
        }
    }
    
    func getIsSelectingImages()->Bool{
        let isSelectingImages = selectedStatus.filter({$0 == true}).count > 0
        return isSelectingImages
    }
    
    func getSelectionSize()->Double{
        var result : Double = 0.0
        for i in 0..<selectedStatus.count{
            result += (selectedStatus[i]) ? items[i].sizeMB : 0
        }
        return (result)
    }
    
    var sourceType : StorageManagerMediaSource
    
    init(vc:ProfileManageStorageSpecificChatOrContentFeedItemVC,tableView:UITableView,imageCollectionView:UICollectionView,source:StorageManagerMediaSource) {
        self.vc = vc
        self.tableView = tableView
        self.imageCollectionView = imageCollectionView
        self.sourceType = source
    }
    
    func finishSetup(items : [StorageManagerItem]){
        self.items = items
        if(sourceType == .podcasts){
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
        }
        else if(sourceType == .chats){
            imageCollectionView.registerCell(ChatImageCollectionViewCell.self)
            imageCollectionView.delegate = self
            imageCollectionView.dataSource = self
            tableView.isHidden = true
        }
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

extension ProfileManageStorageSpecificChatOrContentFeedItemVM : UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChatImageCollectionViewCell.reuseID,
            for: indexPath
        ) as! ChatImageCollectionViewCell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? ChatImageCollectionViewCell,
           let cm = items[indexPath.row].cachedMedia{
            cell.configure(cachedMedia: cm, size: getSize(),selectionStatus: selectedStatus[indexPath.row], memorySizeMB: items[indexPath.row].sizeMB)
        }
    }
    
    func getSize()->CGSize{
        let collectionViewWidth = self.imageCollectionView.bounds.width
        let spacingBetweenCells: CGFloat = 2
        let totalSpacing = (spacingBetweenCells * 2) // Spacing on both sides of the cell
        let cellWidth = (collectionViewWidth - totalSpacing) / 3.25
        let cellHeight = cellWidth // Assuming you want square cells
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return getSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedStatus[indexPath.row] = !selectedStatus[indexPath.row]
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
                        
                        StorageManager.sharedManager.refreshAllStoredData(completion: {
                        })
                    },
                    failureCompletion: {
                        AlertHelper.showAlert(title: "Error", message: "Could not delete the content. Please try again later.")
                    }
                )
            }
        })
    }
}
