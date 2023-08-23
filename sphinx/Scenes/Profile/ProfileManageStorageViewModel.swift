//
//  ProfileManageStorageViewModel.swift
//  sphinx
//
//  Created by James Carucci on 5/22/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageViewModel : NSObject{
    var vc : ProfileManageStorageViewController
    var mediaTypeTableView:UITableView
    var mediaSourceTableView:UITableView
    var mediaTypes = StorageManagerMediaType.allCases
    var sourceTypes = StorageManagerMediaSource.allCases
    var typeStats = [StorageManagerMediaType:Double]()
    var sourceStats = [StorageManagerMediaSource:Double]()
    
    init(
        vc:ProfileManageStorageViewController,
        mediaTypeTableView:UITableView,
        mediaSourceTableView:UITableView
    ){
        self.vc = vc
        self.mediaTypeTableView = mediaTypeTableView
        self.mediaSourceTableView = mediaSourceTableView
    }
    
    func finishSetup(){
        sourceStats = StorageManager.sharedManager.getStorageItemSummaryBySource()
        
        self.mediaTypeTableView.delegate = self
        self.mediaTypeTableView.dataSource = self
        
        self.mediaSourceTableView.delegate = self
        self.mediaSourceTableView.dataSource = self
        
        mediaTypeTableView.register(UINib(nibName: "MediaStorageTypeSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageTypeSummaryTableViewCell.reuseID)
        mediaSourceTableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
        
    }
    
    
}

extension ProfileManageStorageViewModel : UITableViewDelegate,UITableViewDataSource, MediaStorageTypeSummaryTableViewCellDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == mediaTypeTableView){
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MediaStorageTypeSummaryTableViewCell.reuseID,
                for: indexPath
            ) as! MediaStorageTypeSummaryTableViewCell
            cell.delegate = self
            cell.finishSetup()
            cell.setupAsMediaType(type: mediaTypes[indexPath.row])
            cell.storageAmountLabel.text = formatBytes(Int(loadMediaSize(forType: mediaTypes[indexPath.row]) ?? 0))
            vc.isLoading == true ? (cell.showLoading()) : (cell.hideLoading())
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MediaStorageSourceTableViewCell.reuseID,
                for: indexPath
            ) as! MediaStorageSourceTableViewCell
            cell.configure(forSource: sourceTypes[indexPath.row])
            cell.mediaSourceSizeLabel.text = formatBytes(Int(loadMediaSize(forSource: sourceTypes[indexPath.row]) ?? 0))
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == mediaSourceTableView){
            let sourceType = sourceTypes[indexPath.row]
            vc.showSourceDetailsVC(source: sourceType)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == mediaTypeTableView){
            return mediaTypes.count
        }
        else{
            return sourceTypes.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Specify the desired height for your cells
        return 64.0 // Adjust this value according to your requirements
    }
    
    func loadMediaSize(forType:StorageManagerMediaType)->Double?{
        var result : Double? = nil
        result = (typeStats[forType] ?? 0) * 1e6
        return result
    }
    
    func loadMediaSize(forSource:StorageManagerMediaSource)->Double?{
        var result : Double? = nil
        result = (sourceStats[forSource] ?? 0) * 1e6
        return result
    }
    
    func didTapDelete(type: StorageManagerMediaType) {
        self.vc.showDeletionWarningAlert(type: type)
    }

    
    func handleDeletion(type:StorageManagerMediaType){
        vc.setIsLoading()
        switch(type){
        case .audio:
            StorageManager.sharedManager.deleteAllAudioFiles(completion: {
                StorageManager.sharedManager.refreshAllStoredData(completion: {
                    self.refreshData()
                    self.vc.resetIsLoading(type: type)
                })
            })
            break
        case .video:
            StorageManager.sharedManager.deleteAllVideos(completion: {
                StorageManager.sharedManager.refreshAllStoredData(completion: {
                    self.refreshData()
                    self.vc.resetIsLoading(type: type)
                })
            })
            break
        case .photo:
            StorageManager.sharedManager.deleteAllImages(completion: {
                StorageManager.sharedManager.refreshAllStoredData(completion: {
                    self.refreshData()
                    self.vc.resetIsLoading(type: type)
                })
            })
            break
        case .file:
            StorageManager.sharedManager.deleteAllOtherFiles(completion: {
                self.refreshData()
                self.vc.resetIsLoading(type: type)
            })
            break
        }
        print("delete all of \(type)")
    }
    
    func refreshData(){
        self.typeStats = StorageManager.sharedManager.getStorageItemSummaryByType()
        self.vc.storageSummaryView.summaryDict = self.typeStats
        self.sourceStats = StorageManager.sharedManager.getStorageItemSummaryBySource()
        self.vc.usageKB = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
        
        self.vc.updateUsageLabels()
        
        self.mediaTypeTableView.reloadData()
        self.mediaSourceTableView.reloadData()
    
    }
}
