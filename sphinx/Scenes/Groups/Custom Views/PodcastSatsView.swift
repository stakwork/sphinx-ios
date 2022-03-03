//
//  PodcastSatsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PodcastSatsView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var amountSlider: UISlider!
    @IBOutlet weak var suggestedAmountOutOfRangeLabel: UILabel!
    
    let sliderValues = [0,3,3,5,5,8,8,10,10,20,20,40,40,80,80,100]
    
    var chat: Chat! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PodcastSatsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        configureSlider()
        setSliderValue(value: 500)
    }
    
    func configureWith(chat: Chat) {
        self.chat = chat
        
        if let podcast = chat.podcast {
            if let storedAmount = UserDefaults.standard.value(forKey: "podcast-sats-\(chat.id)") as? Int {
                setSliderValue(value: storedAmount)
            } else {
                let suggestedSats = podcast.model?.suggestedSats ?? 0
                setSliderValue(value: suggestedSats)
            }
        }
    }
    
    func setSliderValue(value: Int) {
        let closest = sliderValues.enumerated().min(by:{abs($0.1 - value) < abs($1.1 - value)})!
        amountSlider.setValue(Float(closest.offset), animated: false)
        amountLabel.text = "\(Int(closest.element))"
        
        setOutOfRangeLabel(value: value)
        
        amountSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                break
            case .moved:
                sliderValueChanged(slider)
                break
            case .ended:
                chat.updateMetaData()
                break
            default:
                break
            }
        }
    }
    
    func setOutOfRangeLabel(value: Int) {
        suggestedAmountOutOfRangeLabel.text = ""
        if let max = sliderValues.last, value > max {
            suggestedAmountOutOfRangeLabel.text = String(format: "suggested.out.range".localized, value)
        }
    }
    
    func sliderValueChanged(_ sender: UISlider) {
        let sliderValue = Int(ceil(sender.value))
        let realValue = sliderValues[sliderValue]
        amountLabel.text = "\(realValue)"
        
        UserDefaults.standard.set(realValue, forKey: "podcast-sats-\(chat.id)")
        UserDefaults.standard.synchronize()
        
        setOutOfRangeLabel(value: realValue)
    }
    
    func configureSlider() {
        amountLabel.text = "sats.per.minute".localized
        
        let circleImage = makeCircleWith(size: CGSize(width: 15, height: 15), backgroundColor: UIColor.Sphinx.ReceivedIcon)
        amountSlider.setThumbImage(circleImage, for: .normal)
        amountSlider.setThumbImage(circleImage, for: .highlighted)
    }
    
    fileprivate func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
