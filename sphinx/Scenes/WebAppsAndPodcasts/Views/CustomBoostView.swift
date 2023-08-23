//
//  CustomBoostView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/01/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol CustomBoostViewDelegate : class {
    func didTouchBoostButton(withAmount amount: Int)
    func didStartBoostAmountEdit()
    func didFailToBoost(message:String)
}

class CustomBoostView: UIView {

    weak var delegate: CustomBoostViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var viewGreenContainer: UIView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var whiteCircle: UIView!
    @IBOutlet weak var boostButton: UIButton!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("CustomBoostView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        viewGreenContainer.layer.cornerRadius = viewGreenContainer.frame.height / 2
        whiteCircle.layer.cornerRadius = whiteCircle.frame.height / 2
        
        amountTextField.text = "\(UserContact.kTipAmount)"
        amountTextField.delegate = self
        amountTextField.addDoneToolbar()
    }

    @IBAction func boostButtonTouched() {
        self.endEditing(true)
        
        SoundsPlayer.playHaptic()
        
        if let amountString = amountTextField.text, let amount = Int(amountString), amount > 0 {
            delegate?.didTouchBoostButton(withAmount: amount)
        } else{
            delegate?.didFailToBoost(message:"Please enter non-zero boost amount.")
        }
    }
    
    @objc func boostAmountTouched(){
        amountTextField.text = ""
        delegate?.didStartBoostAmountEdit()
    }
}

extension CustomBoostView : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.boostAmountTouched()
    }
}
