//
//  ProfileManageStorageViewController.swift
//  sphinx
//
//  Created by James Carucci on 5/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageViewController : UIViewController{
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var storageSummaryView: StorageSummaryView!
    @IBOutlet weak var mediaDeletionConfirmationView: MediaDeletionConfirmationView!
    @IBOutlet weak var usedStorageLabel: UILabel!
    @IBOutlet weak var freeStorageLabel: UILabel!
    @IBOutlet weak var changeStorageButton: UIButton!
    @IBOutlet weak var changeStorageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var mediaTypeTableView: UITableView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var mediaSourceTableView: UITableView!
    
    
    @IBOutlet weak var editingModeMaximumLabel: UILabel!
    @IBOutlet weak var editingModeUsedStorageLabel: UILabel!
    
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var sliderVerticalSpacing: NSLayoutConstraint!
    @IBOutlet weak var maxSliderView: MaxMemorySlider!
    var sliderHiddenYConstraint : CGFloat = -8.0
    var sliderShowingYConstraint: CGFloat = 34.0
    
    var tempTypeStats : [StorageManagerMediaType:Double]? = nil
    var tempSourceStats : [StorageManagerMediaSource:Double]? = nil
    var isFirstLoad : Bool = true
    var overlayView : UIView? = nil
    
    var usageKB : Double = 0.0
    var maxGB: Int = 0
    var isEditingMaxMemory : Bool = false {
        didSet{
            storageSummaryView.memorySliderUpdated(value: UserData.sharedInstance.getMaxMemoryGB())
            storageSummaryView.isEditingMaxMemory = isEditingMaxMemory
            if(oldValue == false && isEditingMaxMemory == true){
                
                self.maxSliderView.isHidden = false
                self.cancelButton.isHidden = false
                self.saveButton.isHidden = false
                
                UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
                    self.backButton.setTitle("close", for: .normal)
                    self.titleLabel.text = "Change Storage Limit"
                    
                    self.sliderVerticalSpacing.constant = self.sliderShowingYConstraint
                    self.maxSliderView.superview?.layoutIfNeeded()
                    
                    self.changeStorageButton.alpha = 0.0
                    self.changeStorageLabel.alpha = 0.0
                    self.maxSliderView.alpha = 1.0
                    self.cancelButton.alpha = 1.0
                    self.saveButton.alpha = 1.0
                    self.mediaTypeTableView.isHidden = true
                    self.mediaSourceTableView.isHidden = true
                    self.usedStorageLabel.isHidden = true
                    self.freeStorageLabel.isHidden = true
                },completion: {_ in
                    self.changeStorageButton.isHidden = true
                    self.changeStorageLabel.isHidden = true
                    
                })
            }
            else if(oldValue == true && isEditingMaxMemory == false){
                UIView.animate(withDuration: 0.25, delay: 0, animations: {
                    self.warningView.isHidden = true
                    self.sliderVerticalSpacing.constant = self.sliderHiddenYConstraint
                    self.maxSliderView.superview?.layoutIfNeeded()
                    self.backButton.setTitle("", for: .normal)
                    self.titleLabel.text = "Manage Storage"
                    
                    self.mediaTypeTableView.isHidden = false
                    self.mediaSourceTableView.isHidden = false
                    self.changeStorageButton.alpha = 1.0
                    self.changeStorageLabel.alpha = 1.0
                    self.maxSliderView.alpha = 0.0
                    self.cancelButton.alpha = 0.0
                    self.saveButton.alpha = 0.0
                    self.usedStorageLabel.isHidden = false
                    self.freeStorageLabel.isHidden = false
                },completion: {_ in
                    self.changeStorageButton.isHidden = false
                    self.changeStorageLabel.isHidden = false
                    self.maxSliderView.isHidden = true
                    
                    self.saveButton.isHidden = true
                    self.cancelButton.isHidden = true
                })
            }
            
            editingModeUsedStorageLabel.text = usedStorageLabel.text
            editingModeMaximumLabel.isHidden = !freeStorageLabel.isHidden
            editingModeUsedStorageLabel.isHidden = !usedStorageLabel.isHidden
        }
    }
    
    public var isLoading : Bool = false {
        didSet{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                self.isLoading == true ? (self.showSpinner()) : (self.hideSpinner())
                self.mediaTypeTableView.reloadData()
            })
        }
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
            if(self.mediaDeletionConfirmationView.state == .awaitingApproval){
                self.mediaDeletionConfirmationView.type = type
            }
            
            if let typeStat = self.vm.typeStats[type] {
                self.mediaDeletionConfirmationView.spaceFreedString = formatBytes(Int(1e6 * typeStat))
            }
            
        })
    }
    
    func hideDeletionWarningAlert(){
        self.overlayView?.removeFromSuperview()
        self.overlayView = nil
        
        self.mediaDeletionConfirmationView.isHidden = true
    }
    
    func setIsLoading(){
        mediaDeletionConfirmationView.state = .loading
    }
    
    func resetIsLoading(type:StorageManagerMediaType){
        mediaDeletionConfirmationView.state = .finished
    }
    
    lazy var vm : ProfileManageStorageViewModel = {
        return ProfileManageStorageViewModel(
            vc: self,
            mediaTypeTableView: mediaTypeTableView,
            mediaSourceTableView: mediaSourceTableView
        )
    }()
    
    
    func freeMemory()-> Int {
        return (maxGB * Int(1e9) - Int(usageKB * 1e6))
    }
    
    static func instantiate(
        storageStats:[StorageManagerMediaType:Double]
    ) -> ProfileManageStorageViewController {
        let viewController = StoryboardScene.Profile.profileManageStorageViewController.instantiate()
        viewController.tempTypeStats = storageStats
        viewController.usageKB = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
        viewController.maxGB = UserData.sharedInstance.getMaxMemoryGB()
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(isFirstLoad){
            setupStorageViewsAndModels()
        }
        hideDeletionWarningAlert()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(isFirstLoad == false){
            DispatchQueue.main.async{
                self.setupStorageViewsAndModels()
            }
        }
        
        isFirstLoad = false
    }
    
    func setupStorageViewsAndModels(){
        hideSpinner()
        
        maxSliderView.delegate = self
        vm.typeStats = tempTypeStats ?? [StorageManagerMediaType:Double]()
        tempTypeStats = nil
        storageSummaryView.summaryDict = vm.typeStats
        updateUsageLabels()
        vm.finishSetup()
        
        if(isFirstLoad == false){
            StorageManager.sharedManager.refreshAllStoredData(completion: {
                
                self.vm.refreshData()
            })
        }
    }
    
    func showSpinner() {
        spinner.color = UIColor.white
        spinner.startAnimating()
        
        changeStorageButton.isHidden = true
        changeStorageLabel.isHidden = true
        loadingLabel.isHidden = false
        spinner.isHidden = false
    }
    
    func hideSpinner(){
        changeStorageButton.isHidden = false
        changeStorageLabel.isHidden = false
        loadingLabel.isHidden = true
        spinner.isHidden = true
    }
    
    func showSourceDetailsVC(source:StorageManagerMediaSource){
        var items : [StorageManagerItem]? = nil
        switch(source){
        case .chats:
            items = StorageManager.sharedManager.cachedMedia
            break
        case .podcasts:
            items = StorageManager.sharedManager.downloadedPods
            break
        }
        if let valid_items = items,
        let size = vm.sourceStats[source]{
            let vc = ProfileManageStorageSourceDetailsVC.instantiate(items: valid_items, source: source,sourceTotalSize: size)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func updateUsageLabels(){
        let usage = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
        usedStorageLabel.text = "\(formatBytes(Int(usage*1e6)))"
        freeStorageLabel.text = "\(formatBytes(freeMemory())) Free"
        self.sliderVerticalSpacing.constant = self.sliderHiddenYConstraint
        editingModeMaximumLabel.text = formatBytes(Int(Double(UserData.sharedInstance.getMaxMemoryGB()) * 1e9))
        
        self.maxSliderView.superview?.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.changeStorageButton.layer.masksToBounds = false
        self.changeStorageButton.layer.borderColor = UIColor(red: 0.278, green: 0.318, blue: 0.369, alpha: 1).cgColor
        self.changeStorageButton.layer.borderWidth = 1.0
        self.changeStorageButton.layer.cornerRadius = self.changeStorageButton.frame.height/2.0
        
        self.cancelButton.layer.masksToBounds = false
        self.cancelButton.layer.borderColor = UIColor(red: 0.278, green: 0.318, blue: 0.369, alpha: 1).cgColor
        self.cancelButton.layer.borderWidth = 1.0
        self.cancelButton.layer.cornerRadius = self.cancelButton.frame.height/2.0
        
        self.saveButton.layer.cornerRadius = self.saveButton.frame.height/2.0
        self.view.bringSubviewToFront(self.changeStorageButton)
    }
    
    @IBAction func backButtonTap(_ sender: Any) {
        if(isEditingMaxMemory){
            isEditingMaxMemory = false
        }
        else{
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func changeButtonTap(_ sender: Any) {
        isEditingMaxMemory = true
        maxSliderView.setSlider()
        editingModeMaximumLabel.text = formatBytes(Int(Double(maxSliderView.sliderControl.value) * 1e9))
        self.editingModeMaximumLabel.textColor = UIColor.Sphinx.Text
    }
    
    
    @IBAction func saveTapped(_ sender: Any) {
        UserData.sharedInstance.setMaxMemory(GB: Int(maxSliderView.sliderControl.value))
        isEditingMaxMemory = false
        maxGB = Int(maxSliderView.sliderControl.value)
        updateUsageLabels()
        storageSummaryView.summaryDict = vm.typeStats
        StorageManager.sharedManager.cleanupGarbage {
            StorageManager.sharedManager.refreshAllStoredData(completion: {
                self.setupStorageViewsAndModels()
            })
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        isEditingMaxMemory = false
        
    }
    
    func checkForImmediateDeletion(newMaxGB:Int){
        let maxInBytes = Int(Double(newMaxGB) * 1e9)
        let usageInBytes = Int(usageKB * 1e6)
        if(maxInBytes < usageInBytes){
            let differential = formatBytes(usageInBytes - maxInBytes)
            self.view.bringSubviewToFront(warningView)
            let warningMessage = String(format: NSLocalizedString("saving.limit.warning", comment: ""), differential)            
            self.warningLabel.text = warningMessage
            self.warningView.isHidden = false
            self.editingModeMaximumLabel.textColor = UIColor.Sphinx.PrimaryRed
        }
        else{
            self.warningView.isHidden = true
            self.editingModeMaximumLabel.textColor = UIColor.Sphinx.Text
        }
    }
    
}

func formatBytes(_ bytes: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    
    let byteCount = Double(bytes)
    
    if byteCount >= 1e9 { // Above 1 GB
        let gbCount = byteCount / 1e9
        return "\(formatter.string(from: NSNumber(value: gbCount)) ?? "") GB"
    } else { // Below 1 GB
        let mbCount = byteCount / 1e6
        return "\(formatter.string(from: NSNumber(value: mbCount)) ?? "") MB"
    }
}



extension ProfileManageStorageViewController: MaxMemorySliderDelegate{
    func sliderValueChanged(value:Int){
        checkForImmediateDeletion(newMaxGB: value)
        self.editingModeMaximumLabel.text = formatBytes(Int(Double(value) * 1e9))
        self.storageSummaryView.memorySliderUpdated(value: value)
    }
}

extension ProfileManageStorageViewController : MediaDeletionConfirmationViewDelegate{
    func mediaDeletionConfirmTapped() {
        if let type = mediaDeletionConfirmationView.type{
            vm.handleDeletion(type: type)
        }
    }
    
    func mediaDeletionCancelTapped() {
        if(mediaDeletionConfirmationView.state == .finished){
            mediaDeletionConfirmationView.state = .awaitingApproval
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0501, execute: {
            self.hideDeletionWarningAlert()
        })
    }
}
