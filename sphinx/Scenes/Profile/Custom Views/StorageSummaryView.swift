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
    @IBOutlet weak var additionFootprintView: UIView!
    @IBOutlet weak var otherMemoryFootprintView: UIView!
    
    @IBOutlet weak var audioToOtherHorizontalSpacing: NSLayoutConstraint!
    @IBOutlet weak var totalMemoryFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var imageFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var imageToVideoHorizontalSpacing: NSLayoutConstraint!
    @IBOutlet weak var videoToAudioHorizontalSpacing: NSLayoutConstraint!
    @IBOutlet weak var videoFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var audioFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var otherFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var deletionFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var deletionTrailingEdge: NSLayoutConstraint!
    @IBOutlet weak var additionFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var additionLeadingEdge: NSLayoutConstraint!
    
    let minimumBarPixels = 2.0
    let maxAllowableMemoryMB : Double = Double(UserData.kMaximumMemoryFootprintGB) * 1e3
    
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
                //totalMemoryFootprintWidth.constant = audioFootprintWidth.constant + videoFootprintWidth.constant + imageFootprintWidth.constant
                totalMemoryFootprintView.isHidden = false
                deletionFootprintView.isHidden = false
                additionFootprintView.isHidden = false
                imagesMemoryFootprintView.isHidden = true
                videosMemoryFootprintView.isHidden = true
                audioMemoryFootprintView.isHidden = true
                otherMemoryFootprintView.isHidden = true
                self.bringSubviewToFront(totalMemoryFootprintView)
                
                deletionFootprintWidth.constant = 0
                deletionFootprintView.superview?.layoutIfNeeded()
                totalMemoryFootprintView.superview?.layoutIfNeeded()
            }
            else{
                totalMemoryFootprintWidth.constant = 0
                totalMemoryFootprintView.isHidden = true
                deletionFootprintView.isHidden = true
                additionFootprintView.isHidden = true
                imagesMemoryFootprintView.isHidden = false
                videosMemoryFootprintView.isHidden = false
                audioMemoryFootprintView.isHidden = false
                otherMemoryFootprintView.isHidden = false
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
            imageFootprintWidth.constant = 2
        }
        if let size = dict[.video]{
            videoFootprintWidth.constant = size/Double(max) * maxMemoryFootprintBackgroundView.frame.width
        }
        else{
            videoFootprintWidth.constant = 2
        }
        
        if let size = dict[.audio]{
            audioFootprintWidth.constant = size/Double(max) * maxMemoryFootprintBackgroundView.frame.width
        }
        else{
            audioFootprintWidth.constant = 2
        }
        
        if let size = dict[.file]{
            otherFootprintWidth.constant = size/Double(max) * maxMemoryFootprintBackgroundView.frame.width
        }
        else{
            otherFootprintWidth.constant = 2
        }
        
        imageToVideoHorizontalSpacing.constant = imageFootprintWidth.constant == 0 ? (0.01) : (2)
        videoToAudioHorizontalSpacing.constant = videoFootprintWidth.constant == 0 ? (0.01) : (2)
        audioToOtherHorizontalSpacing.constant = audioFootprintWidth.constant == 0 ? (0.01) : (2)
        
        audioFootprintWidth.constant = (audioFootprintWidth.constant < minimumBarPixels) ? minimumBarPixels : audioFootprintWidth.constant
        videoFootprintWidth.constant = (videoFootprintWidth.constant < minimumBarPixels) ? minimumBarPixels : videoFootprintWidth.constant
        imageFootprintWidth.constant = (imageFootprintWidth.constant < minimumBarPixels) ? minimumBarPixels : imageFootprintWidth.constant
        
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
        let usedMemory = getTotalMemory()
        let differentialMB = Double(value) * 1e3 - usedMemory
        let additionSubLength = CGFloat(abs(differentialMB))/CGFloat(maxAllowableMemoryMB) * maxMemoryFootprintBackgroundView.frame.width
        let usedLength = CGFloat(abs(usedMemory))/CGFloat(maxAllowableMemoryMB) * maxMemoryFootprintBackgroundView.frame.width
        totalMemoryFootprintWidth.constant = usedLength
        
        if(differentialMB < 0){//decreasing footprint
            deletionTrailingEdge.constant = maxMemoryFootprintBackgroundView.frame.width - usedLength
            deletionFootprintWidth.constant = additionSubLength
            additionFootprintWidth.constant = 0
            totalMemoryFootprintView.backgroundColor = UIColor.Sphinx.PrimaryText
        }
        else{
            additionLeadingEdge.constant = usedLength
            additionFootprintWidth.constant = additionSubLength
            self.bringSubviewToFront(additionFootprintView)
            deletionFootprintWidth.constant = 0
            additionFootprintView.backgroundColor = UIColor.Sphinx.PrimaryText
            totalMemoryFootprintView.backgroundColor = UIColor.Sphinx.MainBottomIcons
        }
        
        self.layoutIfNeeded()
        
//        if(value < max){
//            let length = CGFloat(max - value)/CGFloat(max) * maxMemoryFootprintBackgroundView.frame.width
//            deletionFootprintView.isHidden = false
//            UIView.animate(withDuration: 0.1, delay: 0.0, animations: {
//                self.deletionTrailingEdge.constant = self.maxMemoryFootprintBackgroundView.frame.width - self.totalMemoryFootprintView.frame.maxX
//                self.deletionFootprintWidth.constant = length
//                self.deletionFootprintView.layoutIfNeeded()
//            })
//        }
//        else{
//            UIView.animate(withDuration: 0.1, delay: 0.0, animations: {
//                self.deletionFootprintWidth.constant = 0.0
//                let ratio = (self.getTotalMemory() * 1e6)/(Double(value) * 1e9)
//                self.totalMemoryFootprintWidth.constant = ratio * self.maxMemoryFootprintBackgroundView.frame.width
//                self.deletionFootprintView.layoutIfNeeded()
//            })
//        }
    }
}

