//
//  ChatSearchTextFieldView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ChatSearchTextFieldViewDelegate {
    func shouldSearchFor(term: String)
    func didTapSearchCancelButton()
}

class ChatSearchTextFieldView: UIView {
    
    var delegate: ChatSearchTextFieldViewDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var textFieldContainer: UIView!
    @IBOutlet weak var textField: UITextField!
    
    let kPlaceHolder = "Search"
    let kFieldPlaceHolderColor = UIColor.Sphinx.PlaceholderText
    let kTextColor = UIColor.Sphinx.Text
    
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
        
        textField.delegate = self
    }
    
    @IBAction func cancelButtonTouched() {
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
        
        delegate?.shouldSearchFor(term: currentChangedString)
        
        return true
    }
}

