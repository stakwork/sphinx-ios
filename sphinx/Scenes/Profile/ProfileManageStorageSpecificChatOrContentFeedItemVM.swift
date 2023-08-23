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
    var podcastTableView : UITableView
    var imageCollectionView : UICollectionView
    var filesTableView : UITableView
    
    
    var teedUpIndex : Int? = nil
    var mediaItems: [StorageManagerItem] = [] {
        didSet {
            if(sourceType == .chats){
                var consolidatedItems: [StorageManagerItem] = []

                // Dictionary to keep track of the total memory for each filePath and key combination
                var memoryTotals: [String: Double] = [:]

                for item in mediaItems {
                    // Check if the item's filePath and key combination already exists in the consolidatedItems array
                    if let _ = consolidatedItems.firstIndex(where: { $0.cachedMedia?.filePath == item.cachedMedia?.filePath && $0.cachedMedia?.key == item.cachedMedia?.key }) {
                        // If the combination exists, update the memory total by adding the current item's memory
                        memoryTotals[item.cachedMedia?.filePath ?? ""]? += item.sizeMB
                    } else {
                        // If the combination doesn't exist, add the item to the consolidatedItems array and initialize the memory total
                        consolidatedItems.append(item)
                        memoryTotals[item.cachedMedia?.filePath ?? ""] = item.sizeMB
                    }
                }

                // Update the mediaItems with the consolidated items
                self.mediaItems = consolidatedItems

                // Update the memory totals for the consolidated items
                for item in mediaItems {
                    let filePath = item.cachedMedia?.filePath ?? ""
                    item.sizeMB = memoryTotals[filePath] ?? 0.0
                }
                
                self.mediaItems.sort(by: getSortingRule)

                imageCollectionView.reloadData()
            }
            // Update the selected status and reload the collection view or table view
            mediaSelectedStatus = mediaItems.map({ _ in return false })
            fileSelectedStatus = fileItems.map({ _ in return false })
        }
    }
    
    var fileItems : [StorageManagerItem] = []{
        didSet{
            fileItems.sort(by: getSortingRule)
            fileSelectedStatus = fileItems.map({_ in return false})
        }
    }
    
    var mediaSelectedStatus : [Bool] = []{
        didSet{
            vc.deletionSummaryView.isHidden = (getIsSelectingImagesOrPodcasts()) ? false : true
            vc.view.bringSubviewToFront(vc.deletionSummaryView)
            vc.updateDeletionSummaryLabel()
            sourceType == .chats ? (imageCollectionView.reloadData()) : (podcastTableView.reloadData())
        }
    }
    
    var fileSelectedStatus : [Bool] = []{
        didSet{
            vc.deletionSummaryView.isHidden = (getIsSelectingFiles()) ? false : true
            vc.view.bringSubviewToFront(vc.deletionSummaryView)
            vc.updateDeletionSummaryLabel()
            filesTableView.reloadData()
        }
    }
    
    var selectedStatus : [Bool] {
        get {
            if (vc.mediaVsFilesSegmentedControl.selectedSegmentIndex == 1) {
                return fileSelectedStatus
            } else {
                return mediaSelectedStatus
            }
        }
    }
    
    func getSortingRule(_ item1: StorageManagerItem, _ item2: StorageManagerItem) -> Bool {
        // Define your sorting logic here
        return item1.date < item2.date
    }
    
    func removeSelectedItems() {
        var indicesToRemove: [Int] = []
        let statusArray = (vc.mediaVsFilesSegmentedControl.selectedSegmentIndex == 1) ? fileSelectedStatus : mediaSelectedStatus
        
        for (index, isSelected) in statusArray.enumerated() {
            if isSelected {
                indicesToRemove.append(index)
            }
        }
        
        // Sort the indices in descending order
        indicesToRemove.sort(by: >)
        
        // Remove the selected items from the items array
        for index in indicesToRemove {
            if(vc.mediaVsFilesSegmentedControl.selectedSegmentIndex == 1){
                fileItems.remove(at: index)
            }
            else{
                mediaItems.remove(at: index)
            }
        }
        
        // Reset the selected status
        mediaSelectedStatus = mediaItems.map({ _ in return false })
        fileSelectedStatus = fileItems.map({ _ in return false })
        
        // Reload the collection view or table view if needed
        imageCollectionView.reloadData()
        podcastTableView.reloadData()
        filesTableView.reloadData()
    }
    
    func getSelectedCachedMedia()->[CachedMedia]{
        return getSelectedItems().compactMap({$0.cachedMedia})
    }
    
    func getSelectedItems() -> [StorageManagerItem] {
        var selectedItems: [StorageManagerItem] = []
        let statusArray = (vc.mediaVsFilesSegmentedControl.selectedSegmentIndex == 1) ? fileSelectedStatus : mediaSelectedStatus
        let mediaArray = (vc.mediaVsFilesSegmentedControl.selectedSegmentIndex == 1) ? fileItems : mediaItems
        for (index, isSelected) in statusArray.enumerated() {
            if isSelected {
                selectedItems.append(mediaArray[index])
            }
        }
        
        return selectedItems
    }

    
    func getIsSelectingImagesOrPodcasts()->Bool{
        let isSelectingImages = mediaSelectedStatus.filter({$0 == true}).count > 0
        return isSelectingImages
    }
    
    func getIsSelectingFiles()->Bool{
        let isSelectingFiles = fileSelectedStatus.filter({$0 == true}).count > 0
        return isSelectingFiles
    }
    
    func getSelectionSize()->Double{
        var result : Double = 0.0
        for i in 0..<mediaSelectedStatus.count{
            result += (mediaSelectedStatus[i]) ? mediaItems[i].sizeMB : 0
        }
        for j in 0..<fileSelectedStatus.count{
            result += (fileSelectedStatus[j]) ? fileItems[j].sizeMB : 0
        }
        
        return (result)
    }
    
    var sourceType : StorageManagerMediaSource
    
    init(
        vc: ProfileManageStorageSpecificChatOrContentFeedItemVC,
        tableView: UITableView,
        imageCollectionView: UICollectionView,
        filesTableView : UITableView,
        source: StorageManagerMediaSource
    ) {
        self.vc = vc
        self.podcastTableView = tableView
        self.imageCollectionView = imageCollectionView
        self.filesTableView = filesTableView
        self.sourceType = source
    }
    
    func finishSetup(items : [StorageManagerItem]){
        self.mediaItems = items.sorted(by: {$0.date > $1.date}).filter({
            if(sourceType == .chats){
                return $0.type == .video || $0.type == .photo
            }
            else{
                return true
            }
        })
        self.fileItems = items.sorted(by: {$0.date > $1.date}).filter({
            return $0.type != .photo && $0.type != .video
        })
        
        if (sourceType == .podcasts) {
            podcastTableView.delegate = self
            podcastTableView.dataSource = self
            
            podcastTableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
            filesTableView.isHidden = true
            vc.selectedIndexUnderlineView.isHidden = true
            vc.segmentedControlHeight.constant = 0.0
            vc.view.layoutIfNeeded()
        } else if (sourceType == .chats) {
            let flow = AlignedCollectionViewFlowLayout(horizontalAlignment: .left)
            flow.minimumLineSpacing = 0
            flow.minimumInteritemSpacing = 0
            
            imageCollectionView.registerCell(ChatImageCollectionViewCell.self)
            imageCollectionView.delegate = self
            imageCollectionView.dataSource = self
            imageCollectionView.collectionViewLayout = flow
            podcastTableView.isHidden = true
            
            filesTableView.delegate = self
            filesTableView.dataSource = self
            filesTableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
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


extension ProfileManageStorageSpecificChatOrContentFeedItemVM : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaStorageSourceTableViewCell.reuseID,
            for: indexPath
        ) as! MediaStorageSourceTableViewCell
        
        let isSelected = (vc.sourceType == .podcasts) ? mediaSelectedStatus[indexPath.row] : fileSelectedStatus[indexPath.row]
        
        switch(vc.sourceType){
        case .podcasts:
            let item = mediaItems[indexPath.row]
            if let episode = getEpisodeForItem(item: item){
                cell.configure(podcastEpisode: episode, item: item, index: indexPath.row, isSelected: isSelected)
                cell.delegate = self
            }
            cell.selectionStyle = .none
            return cell
        case .chats:
            let file = fileItems[indexPath.row]
            
            cell.configure(fileName: file.cachedMedia?.fileName ?? (file.type == .audio ? "Audio Recording" : "Unknown File"), fileType: file.cachedMedia?.fileExtension ?? ".txt", item: file, index: indexPath.row,isSelected: isSelected)
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(vc.sourceType){
        case .podcasts:
            return mediaItems.count
        case .chats:
            return fileItems.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(sourceType == .podcasts){
            mediaSelectedStatus[indexPath.row] = !mediaSelectedStatus[indexPath.row]
        }
        else if(sourceType == .chats){
            fileSelectedStatus[indexPath.row] = !fileSelectedStatus[indexPath.row]
        }
    }
    
    func playPodcastItem(item:StorageManagerItem){
        if let sourcePath = item.sourceFilePath{
            if let pair = StorageManager.sharedManager.getFeedItemPairForString(string: sourcePath),
            pair.count > 1 {
                
                let feedID = pair[0]
                let itemID = pair[1].replacingOccurrences(of: ".mp3", with: "")
                
                if let feed = FeedsManager.sharedInstance.fetchFeeds().filter({$0.feedID == feedID}).first {
                    let pf = PodcastFeed.convertFrom(contentFeed: feed)
                    self.vc.presentPodcastPlayerFor(pf, itemID: itemID)
                }
            }
        }
    }
}

extension ProfileManageStorageSpecificChatOrContentFeedItemVM : UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
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
           let cm = mediaItems[indexPath.row].cachedMedia{
            cell.configure(cachedMedia: cm, size: getSize(),selectionStatus: mediaSelectedStatus[indexPath.row], memorySizeMB: mediaItems[indexPath.row].sizeMB)
        }
    }
    
    func getSize() -> CGSize {
        let collectionViewWidth = self.imageCollectionView.bounds.width
        let cellWidth: CGFloat = (collectionViewWidth / 3)

        let cellHeight = cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return getSize()
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mediaSelectedStatus[indexPath.row] = !mediaSelectedStatus[indexPath.row]
    }
}


extension ProfileManageStorageSpecificChatOrContentFeedItemVM : MediaStorageSourceTableViewCellDelegate{
    func didTapItemDelete(index: Int) {
        teedUpIndex = index
        vc.mediaDeletionConfirmationView.batchState = .single
        if(sourceType == .podcasts){
            vc.mediaDeletionConfirmationView.source = self.sourceType
            vc.showDeletionWarningAlert(type: .audio)
        }
        else{
            fileSelectedStatus = fileItems.map({_ in return false})
            fileSelectedStatus[index] = true
            vc.mediaDeletionConfirmationView.source = self.sourceType
            vc.showDeletionWarningAlert(type: .file)
        }
        
    }
    
    func finalizeEpisodeDelete(){
        if let index = teedUpIndex,
           let sourcePath = mediaItems[index].sourceFilePath{
            teedUpIndex = nil
            vc.mediaDeletionConfirmationView.batchState = nil
            StorageManager.sharedManager.deletePodEpisodeWithFileName(
                fileName: sourcePath,
                successCompletion: {
                    self.handleConfirmDelete(index: index)
                },
                failureCompletion: {
                    AlertHelper.showAlert(title: "Error", message: "Could not delete the content. Please try again later.")
                }
            )
        }
    }
    
    func handleConfirmDelete(index:Int){
        vc.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(mediaItems[index].sizeMB * 1e6))
        self.mediaItems.remove(at: index)
        self.vc.mediaDeletionConfirmationView.state = .finished
        self.finishSetup(items: self.mediaItems)
        self.vc.setupViewAndModels()
        self.podcastTableView.reloadData()
        
        StorageManager.sharedManager.refreshAllStoredData(completion: {
        })
    }
}
