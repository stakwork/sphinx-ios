//
//  BoostButtonView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol BoostButtonViewDelegate : class {
    func didTouchButton()
}

class BoostButtonView: UIView {
    
    weak var delegate: BoostButtonViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var greenCircle: UIView!
    @IBOutlet weak var boostIcon: UIImageView!
    @IBOutlet weak var boostButton: UIButton!
    @IBOutlet weak var greenCircleWidth: NSLayoutConstraint!
    @IBOutlet weak var boostIconWidth: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("BoostButtonView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        greenCircle.layer.cornerRadius = greenCircle.frame.size.height / 2
    }

    @IBAction func buttonTouched() {
        animateButton()
        delegate?.didTouchButton()
    }
    
    func animateButton() {
        SoundsPlayer.playHaptic()
        
        boostButton.isUserInteractionEnabled = false
        
        greenCircleWidth.constant = 36
        greenCircle.layer.cornerRadius = 18
        greenCircle.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.greenCircle.alpha = 0
            self.boostIconWidth.constant = 50
            self.boostIcon.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.greenCircle.alpha = 1
                self.greenCircleWidth.constant = 28
                self.greenCircle.layer.cornerRadius = 14
                self.boostIconWidth.constant = 22
                self.layoutIfNeeded()
            }, completion: { _ in
                DispatchQueue.main.async {
                    self.boostButton.isUserInteractionEnabled = true
                }
            })
        })
    }
}
