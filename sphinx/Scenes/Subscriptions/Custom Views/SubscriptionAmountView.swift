//
//  SubscriptionAmountView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SubscriptionAmountView : SubscriptionCommonView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var keyboardAccessoryView: UIView!
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var firstCheckbox: UILabel!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondCheckbox: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdCheckbox: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var forthCheckbox: UILabel!
    @IBOutlet weak var forthLabel: UILabel!
    @IBOutlet weak var amountUnitLabel: UILabel!
    @IBOutlet weak var customAmountButton: UIButton!
    
    override func setup() {
        Bundle.main.loadNibNamed("SubscriptionAmountView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.clipsToBounds = true
        
        checkboxesArray = [firstCheckbox, secondCheckbox, thirdCheckbox, forthCheckbox]
        labelsArray = [firstLabel, secondLabel, thirdLabel, forthLabel]
        
        shouldSelectOptionWithIndex(index: subscriptionManager.amountIndexSelected)
        completeField(value: subscriptionManager.customAmount)
        
        amountTextField.layer.borderWidth = 1
        amountTextField.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        amountTextField.layer.cornerRadius = 5
        amountTextField.delegate = self
        amountTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        amountTextField.inputAccessoryView = keyboardAccessoryView
    }
    
    @IBAction func keyboardAccessoryButtonTouched(_ sender: UIButton) {
        if showErrorIfEmpty() {
            return
        }
        
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            if let text = amountTextField.text?.replacingOccurrences(of: " ", with: ""), let intValue = Int(text) {
                subscriptionManager.customAmount = intValue
            }
            break
        case KeyboardButtons.Cancel.rawValue:
            if !shouldRevertValue() {
                return
            }
            break
        default:
            break
        }
        self.endEditing(true)
    }
    
    @IBAction func optionButtonTouched(_ sender: UIButton) {
        shouldSelectOptionWithIndex(index: sender.tag)
        activateOption(index: sender.tag)
    }
    
    func shouldSelectOptionWithIndex(index: Int?) {
        guard let index = index else {
            return
        }
        
        subscriptionManager.amountIndexSelected = index
        super.selectOptionWithIndex(index: index)
        
        let isCustom = index == SubscriptionManager.AmountOptions.customAmount.rawValue
        amountUnitLabel.textColor = isCustom ? kLabelSelectedColor : kLabelUnselectedColor
        customAmountButton.isHidden = isCustom ? true : false
        subscriptionManager.customAmount = isCustom ? subscriptionManager.customAmount : nil
    }
    
    func activateOption(index: Int) {
        let isCustom = index == SubscriptionManager.AmountOptions.customAmount.rawValue
        
        if isCustom {
            amountTextField.becomeFirstResponder()
        } else {
            amountTextField.text = ""
            amountTextField.resignFirstResponder()
        }
    }
}

extension SubscriptionAmountView {
    @objc func textFieldDidChange(textField: UITextField) {
        if let text = textField.text, let intValue = Int(text) {
            completeField(value: intValue)
        }
    }
    
    func completeField(value: Int?) {
        guard let value = value else {
            return
        }
        
        let amountString = value.formattedWithSeparator
        amountTextField.text = amountString
    }
}
