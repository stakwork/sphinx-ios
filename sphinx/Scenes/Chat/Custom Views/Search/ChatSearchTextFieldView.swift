//
//  ChatSearchTextFieldView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ChatSearchTextFieldViewDelegate : class {
    func shouldSearchFor(term: String)
    func didTapSearchCancelButton()
}

class ChatSearchTextFieldView: UIView {
    
    weak var delegate: ChatSearchTextFieldViewDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var textFieldContainer: UIView!
    @IBOutlet weak var textField: UITextField!
    
    let kPlaceHolder = "Search"
    let kFieldPlaceHolderColor = UIColor.Sphinx.PlaceholderText
    let kTextColor = UIColor.Sphinx.Text
    
    var timer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ChatSearchTextFieldView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        textFieldContainer.layer.cornerRadius = textFieldContainer.frame.size.height/2
        textFieldContainer.clipsToBounds = true
        
        textField.delegate = self
    }
    
    func setDelegate(
        _ delegate: ChatSearchTextFieldViewDelegate?
    ) {
        self.delegate = delegate
    }
    
    func makeFieldActive() {
        textField.becomeFirstResponder()
    }
    
    @IBAction func cancelButtonTouched() {
        textField.text = ""
        textField.resignFirstResponder()
        
        delegate?.didTapSearchCancelButton()
    }
}

extension ChatSearchTextFieldView : UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentString = textField.text! as NSString
        let currentChangedString = currentString.replacingCharacters(in: range, with: string)
        
        performSearchWithDelay(term: currentChangedString)
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.delegate?.shouldSearchFor(term: "")
        return true
    }
    
    func performSearchWithDelay(
        term: String
    ) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
            self.delegate?.shouldSearchFor(term: term)
        })
    }
}

