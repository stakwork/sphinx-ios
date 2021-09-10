//
//  SubscriptionEndRuleView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SubscriptionEndRuleView : SubscriptionCommonView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var keyboardAccessoryView: UIView!
    
    @IBOutlet weak var firstCheckbox: UILabel!
    @IBOutlet var firstOptionLabels: [UILabel]!
    @IBOutlet weak var firstOptionTextField: UITextField!
    @IBOutlet weak var secondCheckbox: UILabel!
    @IBOutlet var secondOptionLabels: [UILabel]!
    @IBOutlet weak var secondOptionFieldContainer: UIView!
    @IBOutlet weak var secondOptionTextField: UITextField!
    
    var selectedDate = Date()
    let datePicker = UIDatePicker()
    
    override func setup() {
        Bundle.main.loadNibNamed("SubscriptionEndRuleView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.clipsToBounds = true
        
        checkboxesArray = [firstCheckbox, secondCheckbox]
        multipleLabelsArray = [firstOptionLabels, secondOptionLabels]
        
        shouldSelectOptionWithIndex(index: subscriptionManager.endRuleIndexSelected)
        completeField()
        
        firstOptionTextField.layer.borderWidth = 1
        firstOptionTextField.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        firstOptionTextField.layer.cornerRadius = 5
        firstOptionTextField.delegate = self
        firstOptionTextField.inputAccessoryView = keyboardAccessoryView

        secondOptionFieldContainer.layer.borderWidth = 1
        secondOptionFieldContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        secondOptionFieldContainer.layer.cornerRadius = 5
        secondOptionTextField.delegate = self
        secondOptionTextField.inputAccessoryView = keyboardAccessoryView
        secondOptionTextField.inputView = getDatePicker()
    }
    
    func shouldSelectOptionWithIndex(index: Int?) {
        guard let index = index else {
            return
        }
        
        subscriptionManager.endRuleIndexSelected = index
        super.selectOptionWithIndex(index: index)
    }
    
    func activateOption(index: Int) {
        switch (index) {
        case SubscriptionManager.EndRuleOptions.makeXPayments.rawValue:
            secondOptionTextField.text = ""
            subscriptionManager.endDate = nil
            firstOptionTextField.becomeFirstResponder()
            break
        case SubscriptionManager.EndRuleOptions.limitDate.rawValue:
            firstOptionTextField.text = ""
            subscriptionManager.paymentsCount = nil
            secondOptionTextField.text = selectedDate.getStringFromDate(format: "MM/dd/YYYY")
            secondOptionTextField.becomeFirstResponder()
            break
        default:
            break
        }
    }
    
    @IBAction func keyboardAccessoryButtonTouched(_ sender: UIButton) {
        if showErrorIfEmpty() {
            return
        }
        
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            if let text = firstOptionTextField.text, let intValue = Int(text), currentField == firstOptionTextField {
                subscriptionManager.paymentsCount = intValue
            } else if currentField == secondOptionTextField {
                subscriptionManager.endDate = datePicker.date
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
    
    func completeField() {
        if let paymentsCount = subscriptionManager.paymentsCount {
            firstOptionTextField.text = "\(paymentsCount)"
        }
        
        if let endDate = subscriptionManager.endDate {
            selectedDate = endDate
            secondOptionTextField.text = endDate.getStringFromDate(format: "MM/dd/YYYY")
        }
    }
    
    @IBAction func optionButtonTouched(_ sender: UIButton) {
        shouldSelectOptionWithIndex(index: sender.tag)
        activateOption(index: sender.tag)
    }
    
    func getDatePicker() -> UIDatePicker {
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        datePicker.timeZone = TimeZone(abbreviation: "UTC")
        datePicker.date = selectedDate
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
        return datePicker
    }
    
    @objc func datePickerChanged(picker: UIDatePicker) {
        selectedDate = picker.date
        secondOptionTextField.text = picker.date.getStringFromDate(format: "MM/dd/YYYY")
    }
}
