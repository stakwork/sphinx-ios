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
    func finishedDeleteAll(feedID:String)
}

public enum ProfileManageStorageSpecificChatOrContentFeedItemVCState{
    case single
    case batch
}

class ProfileManageStorageSpecificChatOrContentFeedItemVC : UIViewController{
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var totalSizeLabel: UILabel!
    @IBOutlet weak var podcastListTableView: UITableView!
    @IBOutlet weak var filesListTableView: UITableView!
    
    @IBOutlet weak var deletionSummaryView: UIView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var deletionSummaryCountLabel: UILabel!
    @IBOutlet weak var deletionSummarySizeLabel: UILabel!
    @IBOutlet weak var deletionSummaryButton: UIView!
    @IBOutlet weak var mediaDeletionConfirmationView: MediaDeletionConfirmationView!
    @IBOutlet weak var mediaVsFilesSegmentedControl: UISegmentedControl!
    @IBOutlet weak var selectedIndexUnderlineView: UIView!
    @IBOutlet weak var selectedIndexIndicatorLeadingEdge: NSLayoutConstraint!
    @IBOutlet weak var segmentedControlHeight: NSLayoutConstraint!
    
    fileprivate var state : ProfileManageStorageSpecificChatOrContentFeedItemVCState = .single
    var overlayView : UIView? = nil
    var sourceType : StorageManagerMediaSource = .chats
    var chat : Chat? = nil
    var podcastFeed: PodcastFeed? = nil
    var items : [StorageManagerItem] = []
    var delegate : ProfileManageStorageSpecificChatOrContentFeedItemVCDelegate? = nil
    var isFirstLoad:Bool = true
    var deleteAllInProcess : Bool = false
    
    lazy var vm : ProfileManageStorageSpecificChatOrContentFeedItemVM = {
        ProfileManageStorageSpecificChatOrContentFeedItemVM(vc: self, tableView: self.podcastListTableView,imageCollectionView: self.imageCollectionView, filesTableView: filesListTableView, source: self.sourceType)
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
        hideDeletionWarningAlert()
        setupSegmentedControl()
    }
    
    func setupViewAndModels(){
        filesListTableView.isHidden = true
        mediaVsFilesSegmentedControl.isHidden = (sourceType != .chats)
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
        
        setTotalSizeLabel()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDeleteSelected))
        deletionSummaryButton.addGestureRecognizer(gesture)
        
    }
    
    func setTotalSizeLabel(){
        let allItems = (sourceType == .chats) ? (vm.mediaItems + vm.fileItems) : (vm.mediaItems)
        totalSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: allItems) * 1e6))
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func handleDeleteSelected(){
        state = .single
        mediaDeletionConfirmationView.delegate = self
        mediaDeletionConfirmationView.source = self.sourceType
        showDeletionWarningAlert(type: .audio)
    }
    
    
    @IBAction func deleteAllTapped(_ sender: Any) {
        state = .batch
        mediaDeletionConfirmationView.delegate = self
        mediaDeletionConfirmationView.source = self.sourceType
        showDeletionWarningAlert(type: .audio)
        deleteAllInProcess = true
    }
    
    @IBAction func deletionSummaryCloseTap(_ sender: Any) {
        vm.mediaSelectedStatus = vm.mediaItems.map({_ in return false})
        vm.fileSelectedStatus = vm.fileItems.map({ _ in return false })
    }
    
    func updateDeletionSummaryLabel(){
        deletionSummaryButton.layer.cornerRadius = deletionSummaryButton.frame.height/2.0
        let count = vm.selectedStatus.filter({$0 == true}).count
        deletionSummaryCountLabel.text = "\(String(describing: count))"
        
        deletionSummarySizeLabel.text = formatBytes(Int(1e6 * vm.getSelectionSize()))
    }
    
    func postProcessDeleteSelected(completion: @escaping ()->()){
        self.vm.removeSelectedItems()
        if (self.vm.mediaItems.count == 0){
            StorageManager.sharedManager.refreshAllStoredData(completion: {
                completion()
                self.navigationController?.popViewController(animated: true)
            })
        }
        else{
            completion()
        }
    }
    
    func processDeleteSelected(completion: @escaping ()->()){
        if(sourceType == .chats){
            let cms = self.vm.getSelectedCachedMedia()
            StorageManager.sharedManager.deleteCacheItems(cms: cms, completion: {
                completion()
                self.postProcessDeleteSelected(completion: {
                    
                })
            })
        }
        else if (sourceType == .podcasts){
            let podPaths = self.vm.getSelectedItems().compactMap({$0.sourceFilePath})
            var podCount = podPaths.count
            for podPath in podPaths{
                StorageManager.sharedManager.deletePodEpisodeWithFileName(fileName: podPath,
                successCompletion: {
                    podCount -= 1
                    if((podCount > 0) == false){
                        completion()
                        self.postProcessDeleteSelected(completion: {
                            
                        })
                    }
                },
                failureCompletion: {
                    podCount -= 1
                    if((podCount > 0) == false){
                        completion()
                        self.postProcessDeleteSelected(completion: {

                        })
                    }
                })
            }
        }
        
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
    
    func presentPodcastPlayerFor(
        _ podcast: PodcastFeed,
        itemID: String? = nil
    ) {
        if let itemID = itemID {
            podcast.currentEpisodeId = itemID
        }
        
        let podcastFeedVC = NewPodcastPlayerViewController.instantiate(
            podcast: podcast,
            delegate: self,
            boostDelegate: self
        )
        
        let navController = UINavigationController()
        
        navController.viewControllers = [podcastFeedVC]
        navController.modalPresentationStyle = .automatic
        navController.isNavigationBarHidden = true
        navigationController?.present(navController, animated: true)        
    }
    
    func showDeletionWarningAlert(type:StorageManagerMediaType){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
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
            self.mediaDeletionConfirmationView.batchState = self.state
            if(self.mediaDeletionConfirmationView.state == .awaitingApproval){
                self.mediaDeletionConfirmationView.type = type
            }
            
            if(self.state == .batch){
                self.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: self.vm.mediaItems) * 1e6))
            }
            else if(self.state == .single && self.sourceType == .chats){
                self.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: self.vm.getSelectedItems()) * 1e6))
            }
        })
    }
    
    func hideDeletionWarningAlert(){
        self.overlayView?.removeFromSuperview()
        self.overlayView = nil
        
        self.mediaDeletionConfirmationView.isHidden = true
    }
    
    func setupSegmentedControl(){
        // Set the background color for the selected segment
        mediaVsFilesSegmentedControl.setLayout(tintColor: UIColor.Sphinx.HeaderBG)

        // Customize the title attributes for the selected segment
        let selectedSegmentAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.Sphinx.PrimaryText,
            .font: UIFont(name: "Roboto-Bold", size: 16.0)!
        ]
        
        let deSelectedSegmentAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.Sphinx.WashedOutReceivedText,
            .font: UIFont(name: "Roboto-Bold", size: 16.0)!
        ]

        mediaVsFilesSegmentedControl.setTitleTextAttributes(selectedSegmentAttributes, for: .selected)
        mediaVsFilesSegmentedControl.setTitleTextAttributes(deSelectedSegmentAttributes, for: .normal)

        // Create a CALayer for the underline
        let underlineLayer = CALayer()
        underlineLayer.backgroundColor = UIColor.Sphinx.PrimaryBlue.cgColor  // Set the underline color

        // Set the initial frame for the underline
        let initialSelectedSegmentIndex = 0  // Replace with the desired initial selected segment index
        let initialSegmentFrame = mediaVsFilesSegmentedControl.subviews[initialSelectedSegmentIndex].frame
        let underlineHeight: CGFloat = 2.0  // Set the underline height

        underlineLayer.frame = CGRect(
            x: initialSegmentFrame.minX,
            y: mediaVsFilesSegmentedControl.frame.height - underlineHeight,
            width: initialSegmentFrame.width,
            height: underlineHeight
        )

        // Add the underline layer to the segmented control's layer
        mediaVsFilesSegmentedControl.layer.addSublayer(underlineLayer)

        // Update the underline position when the selected segment changes
        mediaVsFilesSegmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)

    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        selectedIndexUnderlineView.translatesAutoresizingMaskIntoConstraints = false
        let wasOnIndexZero = filesListTableView.isHidden == true
        if (sender.selectedSegmentIndex == 0) {
            filesListTableView.isHidden = true
            imageCollectionView.isHidden = false
            UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                self.selectedIndexIndicatorLeadingEdge.constant = 0
            })
        } else {
            filesListTableView.isHidden = false
            imageCollectionView.isHidden = true
            UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                self.selectedIndexIndicatorLeadingEdge.constant = self.selectedIndexUnderlineView.frame.width
            })
        }
        
        if((sender.selectedSegmentIndex == 0 && wasOnIndexZero == false) ||
           (sender.selectedSegmentIndex != 0 && wasOnIndexZero == true)){
            deletionSummaryView.isHidden = true
            vm.mediaSelectedStatus = vm.mediaItems.map({ _ in return false })
            vm.fileSelectedStatus = vm.fileItems.map({ _ in return false })
        }
    }
}

extension ProfileManageStorageSpecificChatOrContentFeedItemVC : MediaDeletionConfirmationViewDelegate{
    func mediaDeletionCancelTapped() {
        self.hideDeletionWarningAlert()
        self.setTotalSizeLabel()
        let existingState = mediaDeletionConfirmationView.state
        mediaDeletionConfirmationView.state = .awaitingApproval
        if(existingState == .finished){
            if(self.vm.mediaItems.count > 0){
                
            }
            else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func mediaDeletionConfirmTapped() {
        if(state == .batch){
            self.processDeleteAll {
                self.mediaDeletionConfirmationView.state = .finished
                if(self.deleteAllInProcess){
                    self.deleteAllInProcess = false
                    self.navigationController?.popViewController(animated: true)
                    if let feedID = self.podcastFeed?.feedID{
                        self.delegate?.finishedDeleteAll(feedID: feedID)
                    }
                }
            }
        }
        else if sourceType == .chats{
            self.processDeleteSelected {
                self.mediaDeletionConfirmationView.state = .finished
            }
        }
        else if sourceType == .podcasts{
            if(vm.getIsSelectingImagesOrPodcasts()){
                self.processDeleteSelected(completion: {
                    self.mediaDeletionConfirmationView.state = .finished
                })
            }
            else{
                vm.finalizeEpisodeDelete()
            }
        }
        
    }
    
    
}

extension ProfileManageStorageSpecificChatOrContentFeedItemVC : PodcastPlayerVCDelegate, CustomBoostDelegate {
    func willDismissPlayer() {
        
    }
    
    func shouldShareClip(comment: PodcastComment) {
        
    }
    
    func shouldGoToPlayer(podcast: PodcastFeed) {
        
    }
    
    func didFailPlayingPodcast() {
        
    }
    
    func didSendBoostMessage(success: Bool, message: TransactionMessage?) {
        
    }
}
