//
//  StorageSummaryView.swift
//  sphinx
//
//  Created by James Carucci on 5/15/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class StorageSummaryView: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var maxMemoryFootprintBackgroundView: UIView!
    @IBOutlet weak var imagesMemoryFootprintView: UIView!
    @IBOutlet weak var videosMemoryFootprintView: UIView!
    @IBOutlet weak var audioMemoryFootprintView: UIView!
    @IBOutlet weak var totalMemoryFootprintView: UIView!
    @IBOutlet weak var deletionFootprintView: UIView!
    
    @IBOutlet weak var totalMemoryFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var imageFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var imageToVideoHorizontalSpacing: NSLayoutConstraint!
    @IBOutlet weak var videoToAudioHorizontalSpacing: NSLayoutConstraint!
    @IBOutlet weak var videoFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var audioFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var deletionFootprintWidth: NSLayoutConstraint!
    
    let userData = UserData.sharedInstance
    public var summaryDict : [StorageManagerMediaType:Double] = [StorageManagerMediaType:Double](){
        didSet{
            adjustBarWidths(dict: summaryDict)
        }
    }
    
    func getTotalMemory()->Double{
        var result = 0.0
        for type in StorageManagerMediaType.allCases{
            result += summaryDict[type] ?? 0.0
        }
        
        return result
    }
    
    var isEditingMaxMemory : Bool = false{
        didSet{
            if(isEditingMaxMemory){
                totalMemoryFootprintWidth.constant = audioFootprintWidth.constant + videoFootprintWidth.constant + imageFootprintWidth.constant
                totalMemoryFootprintView.isHidden = false
                deletionFootprintView.isHidden = false
                imagesMemoryFootprintView.isHidden = true
                videosMemoryFootprintView.isHidden = true
                audioMemoryFootprintView.isHidden = true
                self.bringSubviewToFront(totalMemoryFootprintView)
                
                deletionFootprintWidth.constant = 0
                deletionFootprintView.superview?.layoutIfNeeded()
                totalMemoryFootprintView.superview?.layoutIfNeeded()
            }
            else{
                totalMemoryFootprintWidth.constant = 0
                totalMemoryFootprintView.isHidden = true
                deletionFootprintView.isHidden = true
                imagesMemoryFootprintView.isHidden = false
                videosMemoryFootprintView.isHidden = false
                audioMemoryFootprintView.isHidden = false
                self.sendSubviewToBack(totalMemoryFootprintView)
                totalMemoryFootprintView.superview?.layoutIfNeeded()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("StorageSummaryView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        totalMemoryFootprintView.isHidden = true
        deletionFootprintView.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
           // self.summaryDict = self.getDebugValues()
        })
    }
    
    func getDebugValues()->[StorageManagerMediaType:Double]{
        let dict : [StorageManagerMediaType:Double] = [
            .photo: 2e3,
            .video:2e3,
            .audio:2e3
        ]
        return dict
    }
    
    private func adjustBarWidths(dict:[StorageManagerMediaType:Double]){
        let max = Double(UserData.sharedInstance.getMaxMemoryGB()) * 1e3
        if let size = dict[.photo]{
            imageFootprintWidth.constant = size/Double(max) * maxMemoryFootprintBackgroundView.frame.width
        }
        else{
            imageFootprintWidth.constant = 0
        }
        if let size = dict[.video]{
            videoFootprintWidth.constant = size/Double(max) * maxMemoryFootprintBackgroundView.frame.width
        }
        else{
            videoFootprintWidth.constant = 0
        }
        
        if let size = dict[.audio]{
            audioFootprintWidth.constant = size/Double(max) * maxMemoryFootprintBackgroundView.frame.width
        }
        else{
            audioFootprintWidth.constant = 0
        }
        
        imageToVideoHorizontalSpacing.constant = imageFootprintWidth.constant == 0 ? (0.01) : (2)
        videoToAudioHorizontalSpacing.constant = videoFootprintWidth.constant == 0 ? (0.01) : (2)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
            self.contentView.layoutIfNeeded()
        })
    }
    
    func getMaxGBLabel(_ gb: Int) -> String {
        return "\(gb) GB"
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.value = roundf(sender.value)
        
        let intValue = Int(sender.value)
        
        
        //userData.setMaxMemory(GB: intValue)
    }
    
    public func memorySliderUpdated(value:Int){
        let max = userData.getMaxMemoryGB()
        if(value < max){
            let length = CGFloat(max - value)/CGFloat(max) * maxMemoryFootprintBackgroundView.frame.width
            deletionFootprintView.isHidden = false
            UIView.animate(withDuration: 0.1, delay: 0.0, animations: {
                self.deletionFootprintWidth.constant = length
                self.deletionFootprintView.layoutIfNeeded()
            })
        }
        else{
            UIView.animate(withDuration: 0.1, delay: 0.0, animations: {
                self.deletionFootprintWidth.constant = 0.0
                let ratio = (self.getTotalMemory() * 1e6)/(Double(value) * 1e9)
                self.totalMemoryFootprintWidth.constant = ratio * self.maxMemoryFootprintBackgroundView.frame.width
                self.deletionFootprintView.layoutIfNeeded()
            })
        }
    }
}

