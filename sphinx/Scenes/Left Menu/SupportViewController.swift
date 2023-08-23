//
//  SupportViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import MessageUI

class SupportViewController: UIViewController {
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var textViewContainer: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var copyLogsButton: UIButton!
    @IBOutlet weak var logsTextView: UITextView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    
    var previousFieldValue : String?
    
    let placeHolderMessage = "support.describe.problem".localized
    
    var mailVC : MFMailComposeViewController?
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate() -> SupportViewController {
        let viewController = StoryboardScene.LeftMenu.supportViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarColor()
        viewTitle.addTextSpacing(value: 2)
        textViewContainer.layer.borderWidth = 1
        textViewContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        textViewContainer.layer.cornerRadius = 5
        
        sendMessageButton.layer.cornerRadius = sendMessageButton.frame.size.height/2
        copyLogsButton.layer.cornerRadius = copyLogsButton.frame.size.height/2
        
        messageTextView.delegate = self
        messageTextView.inputAccessoryView = keyboardAccessoryView
        messageTextView.text = placeHolderMessage
        
        loadLogs()
    }
    
    func loadLogs() {
        loading = true
        
        API.sharedInstance.getLogs(callback: { logs in
            self.loading = false
            self.logsTextView.text = logs
        }, errorCallback: {
            self.loading = false
        })
    }
    
    @IBAction func sendMessageButtonTouched() {
        var emailBody = ""
        
        if let message = messageTextView.text, message != placeHolderMessage {
            emailBody = message
        }
        
        if let logs = logsTextView.text, logs != "" {
            let separator = emailBody == "" ? "" : "\n\n\n"
            emailBody = "\(emailBody)\(separator)\(logs)"
        }
        
        mailVC = EmailHelper(emailBody: emailBody).sendEmail(vc: self)
    }
    
    @IBAction func copyLogsButtonTouched() {
        if let text = logsTextView.text {
            ClipboardHelper.copyToClipboard(text: text, message: "support.logs.copied".localized)
        }
    }
    
    @IBAction func keyboardAccessoryButtonTouched(_ sender: UIButton) {
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            break
        case KeyboardButtons.Cancel.rawValue:
            shouldRevertMessageValue()
            break
        default:
            break
        }
        view.endEditing(true)
    }
    
    @IBAction func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }
}

extension SupportViewController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let text = textView.text, text == placeHolderMessage {
            textView.text = ""
            textView.textColor = UIColor.Sphinx.Text
        }
        previousFieldValue = textView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text, text == "" {
            textView.text = placeHolderMessage
            textView.textColor = UIColor.Sphinx.PlaceholderText
        }
    }
    
    func shouldRevertMessageValue() {
        if let previousFieldValue = previousFieldValue {
            messageTextView.text = previousFieldValue
        }
    }
}

extension SupportViewController : MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        if result == MFMailComposeResult.sent {
            AlertHelper.showAlert(title: "generic.success.title".localized, message: "message.sent".localized, on: self)
        }
    }
}
