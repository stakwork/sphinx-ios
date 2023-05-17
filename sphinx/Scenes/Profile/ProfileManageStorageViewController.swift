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
    
    @IBOutlet weak var sliderVerticalSpacing: NSLayoutConstraint!
    @IBOutlet weak var maxSliderView: MaxMemorySlider!
    var sliderHiddenYConstraint : CGFloat = -8.0
    var sliderShowingYConstraint: CGFloat = 34.0
    
    var stats = [StorageManagerMediaType:Double]()
    var usage : Double = 0.0
    var max: Int = 0
    var isEditingMaxMemory : Bool = false {
        didSet{
            if(oldValue == false && isEditingMaxMemory == true){
                UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
                    self.changeStorageButton.isHidden = true
                    self.changeStorageLabel.isHidden = true
                    self.maxSliderView.isHidden = false
                    self.backButton.setTitle("close", for: .normal)
                    self.titleLabel.text = "Change Storage Limit"
                    
                    self.sliderVerticalSpacing.constant = self.sliderShowingYConstraint
                    self.maxSliderView.superview?.layoutIfNeeded()
                })
            }
            else if(oldValue == true && isEditingMaxMemory == false){
                self.sliderVerticalSpacing.constant = self.sliderHiddenYConstraint
                self.maxSliderView.superview?.layoutIfNeeded()
                self.changeStorageButton.isHidden = false
                self.changeStorageLabel.isHidden = false
                self.maxSliderView.isHidden = true
                self.backButton.setTitle("", for: .normal)
                self.titleLabel.text = "Manage Storage"
            }
        }
    }
    
    
    func freeMemory()-> Int {
        return (max * Int(1e9) - Int(usage * 1e6))
    }
    
    static func instantiate(
        storageStats:[StorageManagerMediaType:Double]
    ) -> ProfileManageStorageViewController {
        let viewController = StoryboardScene.Profile.profileManageStorageViewController.instantiate()
//        viewController.rootViewController = rootViewController
//        viewController.contactsService = rootViewController.contactsService
//        viewController.delegate = delegate
        viewController.stats = storageStats
        viewController.usage = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
        viewController.max = UserData.sharedInstance.getMaxMemoryGB()
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storageSummaryView.adjustBarWidths(dict: stats)
        updateUsageLabels()
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
    }
    
    
}

func formatBytes(_ bytes: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    
    let byteCount = Double(bytes)
    
    if byteCount >= 1e9 { // Above 1 GB
        let gbCount = byteCount / 1e9
        return "\(formatter.string(from: NSNumber(value: gbCount)) ?? "") GB"
    } else { // Below 1 GB
        let mbCount = byteCount / 1e6
        return "\(formatter.string(from: NSNumber(value: mbCount)) ?? "") MB"
    }
}

