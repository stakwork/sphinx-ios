//
//  VideoCallPayButton.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol VideoCallDelegate: class {
    func didTapButton(callback: @escaping () -> ())
    func didSwitchMode(pip: Bool)
    func didFinishCall()
}

class VideoCallPayButton: UIView {
    
    weak var delegate: VideoCallDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var paymentButtonContainer: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var paymentButtonIcon: UIImageView!
    
    var amount: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("VideoCallPayButton", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        paymentButtonContainer.layer.cornerRadius = paymentButtonContainer.frame.size.height / 2
        paymentButtonIcon.layer.cornerRadius = paymentButtonIcon.frame.size.height / 2
        paymentButtonIcon.clipsToBounds = true
    }
    
    func configure(delegata: VideoCallDelegate?, amount: Int) {
        self.delegate = delegata
        self.amount = amount
        
        let amountString = amount.formattedWithSeparator
        amountLabel.text = amountString
    }
    
    func animatePayment() {
        UIView.animate(withDuration: 0.05, animations: {
            self.paymentButtonContainer.alpha = 0.0
        }, completion: {_ in
            UIView.animate(withDuration: 0.05, animations: {
                self.paymentButtonContainer.alpha = 1.0
            })
        })
    }
    
    @IBAction func buttonTouched() {
        let kButtonColorEnable = UIColor.Sphinx.PrimaryGreen
        let kButtonColorDisable = UIColor.Sphinx.WashedOutGreen
        
        paymentButtonContainer.backgroundColor = kButtonColorDisable
        paymentButtonContainer.isUserInteractionEnabled = false
        
        delegate?.didTapButton {
            self.paymentButtonContainer.backgroundColor = kButtonColorEnable
            self.paymentButtonContainer.isUserInteractionEnabled = true
        }
    }
}
