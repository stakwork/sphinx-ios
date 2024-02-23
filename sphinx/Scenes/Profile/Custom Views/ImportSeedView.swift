//
//  StorageSummaryView.swift
//  sphinx
//
//  Created by James Carucci on 5/15/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ImportSeedViewDelegate : NSObject{
    func showImportSeedView(network:String,host:String,relay:String)//TODO: review this before shipping prod. May not need this anymore
    func showImportSeedView()
    func didTapCancelImportSeed()
    func didTapConfirm()
}

public enum ImportSeedViewPresentationContext{
    case SphinxOnionPrototype
    case Swarm
}

class ImportSeedView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var textViewContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityViewContainer: UIView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var delegate : ImportSeedViewDelegate? = nil
    var context : ImportSeedViewPresentationContext = .Swarm
    
    var originalFrame: CGRect = .zero
    var isKeyboardShown = false
    var network:String = ""
    var host:String = ""
    var relay:String = ""
    
    var isLoading:Bool = false {
        didSet{
            if(isLoading == false){
                activityView.stopAnimating()
                activityViewContainer.isHidden = true
            }
            else{
                activityViewContainer.isHidden = false
                activityView.startAnimating()
            }
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
        
        activityView.color = UIColor.Sphinx.Text
        
        textView.delegate = self
        
        textViewContainer.layer.cornerRadius = 10
        textViewContainer.layer.borderWidth = 1
        textViewContainer.layer.borderColor = UIColor.Sphinx.LightDivider.cgColor
        
        confirmButton.layer.cornerRadius = confirmButton.frame.height/2.0
        cancelButton.layer.cornerRadius = cancelButton.frame.height/2.0
        contentView.layer.cornerRadius = 34.0
        textView.layer.cornerRadius = 4.0
    }
    
    func showWith(
        delegate: ImportSeedViewDelegate?,
        network: String,
        host: String,
        relay: String
    ) {
        self.delegate = delegate
        self.network = network
        self.host = host
        self.relay = relay
        
        textView.becomeFirstResponder()
    }
    
    func showWith(
        delegate: ImportSeedViewDelegate?
    ) {
        self.delegate = delegate
        
        textView.becomeFirstResponder()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        textView.resignFirstResponder()
        textView.text = ""
        
        self.isLoading = false
        
        delegate?.didTapCancelImportSeed()
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        let words = textView.text.split(separator: " ").map { String($0).trim().lowercased() }
        let (error, additionalString) = CrypterManager.sharedInstance.validateSeed(words: words)
        
        if let error = error {
            AlertHelper.showAlert(
                title: "profile.seed-validation-error-title".localized,
                message: error.localizedDescription + (additionalString ?? "")
            )
            return
        }
        
        textView.resignFirstResponder()
        isLoading = true
        
        delegate?.didTapConfirm()
    }
}


extension ImportSeedView:UITextViewDelegate {
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        if !isKeyboardShown {
            originalFrame = frame
            isKeyboardShown = true
            
            frame = CGRect(
                x: originalFrame.minX,
                y: originalFrame.minY - keyboardFrame.height/2.0,
                width: originalFrame.width,
                height: originalFrame.height
            )
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
