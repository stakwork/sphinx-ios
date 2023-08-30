//
//  StorageSummaryView.swift
//  sphinx
//
//  Created by James Carucci on 5/15/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ImportSeedViewDelegate : NSObject{
    func didTapCancelImportSeed()
    func didTapConfirm()
}

class ImportSeedView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    
    var delegate : ImportSeedViewDelegate? = nil
    var originalFrame: CGRect = .zero
    var isKeyboardShown = false
    var network:String = ""
    var host:String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    private func setup() {
        Bundle.main.loadNibNamed("ImportSeedView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.backgroundColor = .clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        textView.delegate = self
        
        
        confirmButton.layer.cornerRadius = confirmButton.frame.height/2.0
        cancelButton.layer.cornerRadius = cancelButton.frame.height/2.0
        contentView.layer.cornerRadius = 34.0
        textView.layer.cornerRadius = 4.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
           // self.summaryDict = self.getDebugValues()
        })
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.didTapCancelImportSeed()
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        delegate?.didTapConfirm()
    }

}


extension ImportSeedView:UITextViewDelegate {
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        if !isKeyboardShown {
            originalFrame = frame
            isKeyboardShown = true
            frame = CGRect(x: originalFrame.minX, y: originalFrame.minY - keyboardFrame.height/2.0, width: originalFrame.width, height: originalFrame.height)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if isKeyboardShown {
            isKeyboardShown = false
            frame = originalFrame
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
