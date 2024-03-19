//
//  AuthorizeAppView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol AuthorizeAppViewDelegate: class {
    func shouldAuthorizeWith(dict: [String: AnyObject])
    func shouldAuthorizeBudgetWith(amount: Int, dict: [String: AnyObject])
    func shouldClose()
}

class AuthorizeAppView: UIView {
    
    weak var delegate: AuthorizeAppViewDelegate?
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var amountFieldContainer: UIView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var authorizeButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var fieldTopLabel: UILabel!
    @IBOutlet weak var fieldBottomLabel: UILabel!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    
    var previousFieldValue : String?
    var dict : [String: AnyObject] = [:]
    
    let kAccessoryViewHeight: CGFloat = 58
    let kHeightWithBudgetField: CGFloat = 400
    let kHeightWithoutBudgetField: CGFloat = 300
    
    var confirmButtonEnabled = false {
        didSet {
            authorizeButton.isEnabled = confirmButtonEnabled
            authorizeButton.alpha = confirmButtonEnabled ? 1.0 : 0.7
        }
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: self)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("AuthorizeAppView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureFor(
        url: String,
        delegate: AuthorizeAppViewDelegate, 
        dict: [String: AnyObject],
        showBudgetField: Bool
    ) -> CGFloat {
        self.delegate = delegate
        self.dict = dict
        
        loading = false
        
        if let url = URL(string: url), let host = url.host {
            appNameLabel.text = host
        } else {
            appNameLabel.text = url
        }
        
        configureView()
        
        let noBudget = (dict["noBudget"] as? Bool) ?? false
        
        if noBudget || !showBudgetField {
            configureWithNoBudget()
            return kHeightWithoutBudgetField
        } else {
            configureWithBudget()
            return kHeightWithBudgetField
        }
    }
    
    func configureWithNoBudget() {
        fieldTopLabel.isHidden = true
        amountFieldContainer.isHidden = true
        fieldBottomLabel.isHidden = true
        confirmButtonEnabled = true
    }
    
    func configureWithBudget() {
        fieldTopLabel.isHidden = false
        amountFieldContainer.isHidden = false
        fieldBottomLabel.isHidden = false
        confirmButtonEnabled = false
    }
    
    func configureView() {
        if let amount = getAmountFrom(string: amountTextField.text) {
            confirmButtonEnabled = (amount > 0)
        } else {
            confirmButtonEnabled = true
        }
        
        authorizeButton.layer.cornerRadius = authorizeButton.frame.height / 2
        
        amountFieldContainer.layer.cornerRadius = amountFieldContainer.frame.height / 2
        amountFieldContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        amountFieldContainer.layer.borderWidth = 1
        
        amountTextField.delegate = self
        amountTextField.inputAccessoryView = keyboardAccessoryView
    }
    
    @IBAction func closeButtonTouched() {
        delegate?.shouldClose()
    }
    
    @IBAction func authorizeButtonTouched() {
        loading = true
        
        if let amount = getAmountFrom(string: amountTextField.text) {
            delegate?.shouldAuthorizeBudgetWith(
                amount: amount,
                dict: dict
            )
        } else {
            delegate?.shouldAuthorizeWith(dict: dict)
        }
    }
    
    @IBAction func keyboardButtonTouched(_ sender: UIButton) {
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            break
        case KeyboardButtons.Cancel.rawValue:
            shouldRevertValue()
            break
        default:
            break
        }
        self.endEditing(true)
    }
    
    func shouldRevertValue() {
        if let currentField = amountTextField, let previousFieldValue = previousFieldValue {
            currentField.text = previousFieldValue
        }
    }
}

extension AuthorizeAppView : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString
        
        if let amount = getAmountFrom(string: String(currentString)) {
            let walletBalance = WalletBalanceService().balance
            
            if amount > walletBalance {
                NewMessageBubbleHelper().showGenericMessageView(text: "balance.too.low".localized)
                return false
            }
            
            if amount > 100000 {
                return false
            }
            
            confirmButtonEnabled = (amount > 0)
            return true
        }
        
        return false
    }
    
    func getAmountFrom(string: String?) -> Int? {
        if amountFieldContainer.isHidden {
            return nil
        } else {
            if let string = string {
                let amount = Int(string) ?? 0
                return amount
            }
        }
        return nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        previousFieldValue = textField.text
    }
}
