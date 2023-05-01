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
    
    var podcast: PodcastFeed! = nil
    
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
        setSliderValue(value: 7)
    }
    
    func configureWith(podcast: PodcastFeed) {
        self.podcast = podcast
        
        if podcast.destinationsArray.isEmpty {
            alpha = 0.5
            
            setSliderValue(value: 0)
            amountSlider.isUserInteractionEnabled = false
            titleLabel.text = "sats.stream.disabled".localized
            
            return
        }
        
        if let storedAmount = podcast.satsPerMinute {
            setSliderValue(value: storedAmount)
        } else {
            let suggestedSats = podcast.model?.suggestedSats ?? 5
            setSliderValue(value: suggestedSats)
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
                if let podcast = podcast {
                    FeedsManager.sharedInstance.saveContentFeedStatus(for: podcast.feedID)
                }
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

        podcast.satsPerMinute = realValue

        setOutOfRangeLabel(value: realValue)
    }
    
    func configureSlider() {
        amountLabel.text = "sats.per.minute".localized
        
        let circleImage = makeCircleWith(size: CGSize(width: 15, height: 15), backgroundColor: UIColor.white)
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
