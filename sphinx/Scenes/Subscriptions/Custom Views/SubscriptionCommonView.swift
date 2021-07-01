//
//  SubscriptionCommonView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

enum KeyboardButtons: Int {
    case Cancel
    case Done
}

protocol SubscriptionFormViewDelegate: class {
    func shouldShowAlert(title: String, text: String)
    func shouldScrollToBottom()
}

class SubscriptionCommonView : UIView {
    
    var delegate: SubscriptionFormViewDelegate!
    
    var checkboxesArray = [UILabel]()
    var labelsArray = [UILabel]()
    var multipleLabelsArray = [[UILabel]]()
    
    var currentField : UITextField?
    var previousFieldValue : String?
    
    let subscriptionManager = SubscriptionManager.sharedInstance
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {}
    
    let kCheckboxUnselectedChar = ""
    let kCheckboxUnselectedColor = UIColor.Sphinx.SecondaryText
    let kCheckboxSelectedChar = ""
    let kCheckboxSelectedColor = UIColor.Sphinx.PrimaryBlue
    
    let kLabelSelectedColor = UIColor.Sphinx.PrimaryText
    let kLabelSuboptionSelectedColor = UIColor.Sphinx.PrimaryText
    let kLabelUnselectedColor = UIColor.Sphinx.SecondaryText
    
    func selectOptionWithIndex(index: Int, fontName: String = "Roboto-Regular", selectedLabelColor: UIColor = UIColor.Sphinx.PrimaryText) {
        
        for (i, checkbox) in checkboxesArray.enumerated() {
            checkbox.text = (index == i) ? kCheckboxSelectedChar : kCheckboxUnselectedChar
            checkbox.textColor = (index == i) ? kCheckboxSelectedColor : kCheckboxUnselectedColor
        }
        
        for (i, label) in labelsArray.enumerated() {
            label.font = UIFont(name: (index == i) ? fontName : "Roboto-Regular", size: 17.0)!
            label.textColor = (index == i) ? selectedLabelColor : kLabelUnselectedColor
        }
        
        for (i, labels) in multipleLabelsArray.enumerated() {
            for label in labels {
                label.textColor = (index == i) ? kLabelSelectedColor : kLabelUnselectedColor
            }
        }
    }
    
    func showErrorIfEmpty() -> Bool {
        if let field = currentField, let text = field.text, text == "" {
            delegate?.shouldShowAlert(title: "generic.error.title".localized, text: "value.cannot.empty".localized)
            return true
        }
        return false
    }
}

extension SubscriptionCommonView : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentField = textField
        previousFieldValue = textField.text
    }
    
    func shouldRevertValue() -> Bool {
        if let currentField = currentField, let previousFieldValue = previousFieldValue, previousFieldValue != "" {
            currentField.text = previousFieldValue
            return true
        }
        delegate?.shouldShowAlert(title: "generic.error.title".localized, text: "value.cannot.empty".localized)
        return false
    }
}
