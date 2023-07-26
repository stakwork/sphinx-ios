//
//  ProfileManageStorageSourceDetailsVC.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

public enum PMSSDVCPresentationContext{
    case memoryManagement
    case downloadedPodcastList
}

class ProfileManageStorageSourceDetailsVC : UIViewController{
    
    
    @IBOutlet weak var tableYOffset: NSLayoutConstraint!
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var mediaSourceDetailsTableView: UITableView!
    @IBOutlet weak var mediaSourceTotalSizeLabel: UILabel!
    @IBOutlet weak var mediaDeletionConfirmationView: MediaDeletionConfirmationView!
    var overlayView : UIView? = nil
    
    var source : StorageManagerMediaSource = .chats
    var totalSize : Double = 0.0
    var isFirstLoad : Bool = true
    var presentationContext : PMSSDVCPresentationContext = .memoryManagement
    
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
        if(isFirstLoad == true){
            setupView()
            vm.finishSetup()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(isFirstLoad == false){
            vm.finishSetup()
            mediaSourceDetailsTableView.reloadData()
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
        hideDeletionWarningAlert()
        if(presentationContext == .downloadedPodcastList){
            adjustViewForDownloadedContext()
        }
    }
    
    func adjustViewForDownloadedContext(){
        self.tableYOffset.constant = 0
        self.headerView.isHidden = true
        headerHeight.constant = 0
        self.view.layoutIfNeeded()
    }
    
    func showDeletionWarningAlert(source:StorageManagerMediaSource){
        switch(source){
        case .chats:
            mediaDeletionConfirmationView.source = .chats
            showDeletionWarningAlert(type: .audio)
            break
        case .podcasts:
            showDeletionWarningAlert(type: .audio)
            break
        }
    }
    
    
    func showDeletionWarningAlert(type:StorageManagerMediaType){
        setupDeletionWarningAlert()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: {
            (self.mediaDeletionConfirmationView.state != .awaitingApproval) ? () : (self.mediaDeletionConfirmationView.type = type)
            let size = StorageManager.sharedManager.getItemGroupTotalSize(items: self.vm.getSourceItems().filter({$0.type == type}))
            self.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(1e6 * size))
        })
    }
    
    func setupDeletionWarningAlert(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
            self.overlayView = UIView(frame: self.view.frame)
            if let overlayView = self.overlayView{
                overlayView.backgroundColor = .black
                overlayView.isUserInteractionEnabled = false
                overlayView.alpha = 0.8
                self.view.addSubview(overlayView)
                self.view.bringSubviewToFront(overlayView)
            }
            self.view.bringSubviewToFront(self.mediaDeletionConfirmationView)
            self.mediaDeletionConfirmationView.layer.zPosition = 1000
            self.mediaDeletionConfirmationView.delegate = self
            self.mediaDeletionConfirmationView.isHidden = false
        })
    }
    
    func hideDeletionWarningAlert(){
        self.overlayView?.removeFromSuperview()
        self.overlayView = nil
        
        self.mediaDeletionConfirmationView.isHidden = true
    }
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func deleteAllTapped(_ sender: Any) {
        print("deleteAllTapped")
        
        showDeletionWarningAlert(source: source)
    }
    
    func handleReset(showFinishedView:Bool=false){
        let predeletionTotal = totalSize
        StorageManager.sharedManager.refreshAllStoredData {
            self.vm.finishSetup()
            self.totalSize = StorageManager.sharedManager.getItemGroupTotalSize(items: self.vm.getSourceItems())
            self.setupView()
            self.vm.tableView.reloadData()
        }
        if(mediaDeletionConfirmationView.state == .finished){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.showDeletionWarningAlert(type: .audio)
                self.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(predeletionTotal * 1e6))
            })
        }
    }
    
    func showItemSpecificDetails(podcastFeed:PodcastFeed?,chat:Chat?,sourceType:StorageManagerMediaSource,items:[StorageManagerItem]){
        let vc = ProfileManageStorageSpecificChatOrContentFeedItemVC.instantiate(podcastFeed: podcastFeed, chat: chat, sourceType: sourceType,items: items)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension ProfileManageStorageSourceDetailsVC : ProfileManageStorageSpecificChatOrContentFeedItemVCDelegate{
    func finishedDeleteAll(feedID:String) {
        if let podIndex = vm.podsArray.firstIndex(where: {$0.feedID == feedID})
           {
            let pod = vm.podsArray[podIndex]
            self.vm.podsArray.remove(at: podIndex)
            if let podDict = vm.podsDict,
                let podItem = podDict[pod]{
                vm.podsDict?.removeValue(forKey: pod)
                totalSize -= StorageManager.sharedManager.getItemGroupTotalSize(items: podItem)
                mediaSourceTotalSizeLabel.text = formatBytes(Int(totalSize*1e6))
            }
            isFirstLoad = true//override reload
            vm.tableView.reloadData()
        }
        if(vm.podsArray.count == 0){
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension ProfileManageStorageSourceDetailsVC : MediaDeletionConfirmationViewDelegate{
    func mediaDeletionCancelTapped() {
        print("CANCEL TAPPED")
        self.hideDeletionWarningAlert()
        if(mediaDeletionConfirmationView.state == .finished){
            mediaDeletionConfirmationView.state = .awaitingApproval
            handleReset()
        }
        
    }
    
    func mediaDeletionConfirmTapped() {
        mediaDeletionConfirmationView.state = .loading
        switch(source){
        case .chats:
            StorageManager.sharedManager.deleteAllImages(completion: {
                StorageManager.sharedManager.deleteAllVideos(completion: {
                    StorageManager.sharedManager.refreshAllStoredData(completion: {
                        self.deletionCompletionHandler()
                    })
                })
            })
            break
        case .podcasts:
            StorageManager.sharedManager.deleteAllAudioFiles(completion: {
                self.deletionCompletionHandler()
            })
            break
        }
    }
    
    func deletionCompletionHandler(){
        self.mediaDeletionConfirmationView.state = .finished
        self.handleReset()
    }
    
    
}
