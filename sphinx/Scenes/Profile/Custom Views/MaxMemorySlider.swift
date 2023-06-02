//
//  MaxMemorySlider.swift
//  sphinx
//
//  Created by James Carucci on 5/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MaxMemorySliderDelegate:NSObject{
    func sliderValueChanged(value:Int)
}

class MaxMemorySlider: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var sliderControl: UISlider!
    @IBOutlet weak var maxMemoryLabel: UILabel!
    
    let userData = UserData.sharedInstance
    var delegate: MaxMemorySliderDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MaxMemorySlider", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        sliderControl.minimumValue = Float(UserData.kMinimumMemoryFootprintGB)
        sliderControl.maximumValue = Float(UserData.kMaximumMemoryFootprintGB)
        
        let image : UIImage? = #imageLiteral(resourceName: "pentagonSlider")
        if let thumbImage = image?.resizeImage(newSize: CGSize(width: 24.0, height: 32.0)) {
            sliderControl.setThumbImage(thumbImage, for: .normal)
        }
        
        setSlider()
    }
    
    public func setSlider(){
        let gb = userData.getMaxMemoryGB()
        sliderControl.value = Float(gb)
        maxMemoryLabel.text = getMaxGBLabel(gb)
    }
    
    func getMaxGBLabel(_ gb: Int) -> String {
        return "\(Int(sliderControl.maximumValue)) GB"
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        sender.value = roundf(sender.value)
        
        let intValue = Int(sender.value)
        //maxMemoryLabel.text = getMaxGBLabel(intValue)
        delegate?.sliderValueChanged(value: intValue)
        //userData.setMaxMemory(GB: intValue)
    }
}
