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
    @IBOutlet weak var usedStorageLabel: UILabel!
    @IBOutlet weak var freeStorageLabel: UILabel!
    @IBOutlet weak var changeStorageButton: UIButton!
    @IBOutlet weak var changeStorageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var mediaTypeTableView: UITableView!
    @IBOutlet weak var loadingSpinnerContainerView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var sliderVerticalSpacing: NSLayoutConstraint!
    @IBOutlet weak var maxSliderView: MaxMemorySlider!
    var sliderHiddenYConstraint : CGFloat = -8.0
    var sliderShowingYConstraint: CGFloat = 34.0
    
    var tempStats : [StorageManagerMediaType:Double]? = nil
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
                    self.changeStorageButton.alpha = 1.0
                    self.changeStorageLabel.alpha = 1.0
                    self.maxSliderView.alpha = 0.0
                    self.cancelButton.alpha = 0.0
                    self.saveButton.alpha = 0.0
                },completion: {_ in
                    self.changeStorageButton.isHidden = false
                    self.changeStorageLabel.isHidden = false
                    self.maxSliderView.isHidden = true
                    
                    self.saveButton.isHidden = true
                    self.cancelButton.isHidden = true
                })
            }
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
    
    func setIsLoading(){
        self.isLoading = true
    }
    
    func resetIsLoading(){
        self.isLoading = false
    }
    
    lazy var vm : ProfileManageStorageViewModel = {
        return ProfileManageStorageViewModel(vc: self, tableView: mediaTypeTableView)
    }()
    
    
    func freeMemory()-> Int {
        return (maxGB * Int(1e9) - Int(usageKB * 1e6))
    }
    
    static func instantiate(
        storageStats:[StorageManagerMediaType:Double]
    ) -> ProfileManageStorageViewController {
        let viewController = StoryboardScene.Profile.profileManageStorageViewController.instantiate()
        viewController.tempStats = storageStats
        viewController.usageKB = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
        viewController.maxGB = UserData.sharedInstance.getMaxMemoryGB()
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        maxSliderView.delegate = self
        vm.stats = tempStats ?? [StorageManagerMediaType:Double]()
        tempStats = nil
        storageSummaryView.summaryDict = vm.stats
        updateUsageLabels()
        vm.finishSetup()
    }
    
    func showSpinner() {
        spinner.color = UIColor.white
        spinner.frame = loadingSpinnerContainerView.frame

        spinner.sizeToFit()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loadingSpinnerContainerView.addSubview(spinner)
        
        spinner.startAnimating()
        changeStorageButton.isHidden = true
        changeStorageLabel.isHidden = true
        loadingSpinnerContainerView.isHidden = false
        loadingLabel.isHidden = false
    }
    
    func hideSpinner(){
        self.changeStorageButton.isHidden = false
        self.changeStorageLabel.isHidden = false
        self.loadingSpinnerContainerView.isHidden = true
        self.loadingLabel.isHidden = true
    }
    
    
    func updateUsageLabels(){
        let usage = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
        usedStorageLabel.text = "\(formatBytes(Int(usage*1e6)))"
        freeStorageLabel.text = "\(formatBytes(freeMemory())) Free"
        self.sliderVerticalSpacing.constant = self.sliderHiddenYConstraint
        
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
        print("changeButtonTap")
        isEditingMaxMemory = true
        maxSliderView.setSlider()
    }
    
    
    @IBAction func saveTapped(_ sender: Any) {
        print("saveTapped")
        UserData.sharedInstance.setMaxMemory(GB: Int(maxSliderView.sliderControl.value))
        isEditingMaxMemory = false
        maxGB = Int(maxSliderView.sliderControl.value)
        updateUsageLabels()
        storageSummaryView.summaryDict = vm.stats
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
            self.warningLabel.text = "Saving this limit will delete \(differential) of your oldest data"
            self.warningView.isHidden = false
        }
        else{
            self.warningView.isHidden = true
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
        self.storageSummaryView.memorySliderUpdated(value: value)
    }
}
