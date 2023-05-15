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
    @IBOutlet weak var imageFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var videoFootprintWidth: NSLayoutConstraint!
    @IBOutlet weak var audioFootprintWidth: NSLayoutConstraint!
    
    let userData = UserData.sharedInstance
    
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
    }
    
    func adjustBarWidths(dict:[StorageManagerMediaType:Double]){
        let max = Double(UserData.sharedInstance.getMaxMemory()) * 1e3
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
        
        UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
            self.superview?.layoutSubviews()
        })
    }
    
    func getMaxGBLabel(_ gb: Int) -> String {
        return "\(gb) GB"
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.value = roundf(sender.value)
        
        let intValue = Int(sender.value)

        userData.setMaxMemory(GB: intValue)
    }
}

