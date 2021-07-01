//
//  AttachmentPriceViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol AttachmentPriceDelegate: class {
    func shouldHidePriceChildVC(amount: Int?)
}

class AttachmentPriceViewController: UIViewController {
    
    weak var delegate: AttachmentPriceDelegate?
    
    @IBOutlet weak var keyPadView: NewKeyPadView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    var price:Int = 0
    
    static func instantiate(delegate: AttachmentPriceDelegate, price: Int) -> AttachmentPriceViewController {
        let viewController = StoryboardScene.Chat.attachmentPriceViewController.instantiate()
        viewController.delegate = delegate
        viewController.price = price
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.layer.cornerRadius = confirmButton.frame.size.height / 2
        confirmButton.clipsToBounds = true
        
        setupKeyPad()
    }
    
    private func setupKeyPad() {
        keyPadView.handler = { [weak self] in
            self?.updateKeyPadString(input: $0) ?? false
        }
        
        if price > 0 {
            keyPadView.setDefaultValue(number: price)
            let amountString = price.formattedWithSeparator
            amountTextField.text = amountString
        }
    }
    
    private func updateKeyPadString(input: String) -> Bool {
        let amount = Int(input) ?? 0
        let amountString = amount.formattedWithSeparator
        amountTextField.text = (amount > 0) ? amountString : ""
        return true
    }
    
    @IBAction func confirmButtonTouched() {
        let amountString = (amountTextField.text ?? "0").amountWithoutSpaces
        let amount = Int(amountString) ?? 0
        delegate?.shouldHidePriceChildVC(amount: amount)
    }
}
