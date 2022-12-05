//
//  Library
//
//  Created by Tomas Timinskas on 22/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol QRCodeScannerDelegate: class {
    @objc optional func didScanQRCode(string: String)
    @objc optional func shouldGoToChat()
    @objc optional func willDismissPresentedView(paymentCreated: Bool)
    @objc optional func didScanDeepLink()
    @objc optional func didScanPublicKey(string: String)
}

class NewQRScannerViewController: KeyboardEventsViewController {
    
    var rootViewController : RootViewController!
    
    weak var delegate: QRCodeScannerDelegate?

    @IBOutlet weak var codeScannerView: QRCodeScannerView! {
        didSet {
            codeScannerView.handler = { [weak self] address in
                self?.codeScanned(code: address)
            }
        }
    }
    
    enum Mode: Int {
        case ScanAndProcess
        case DirectPayment
        case ScanAndDismiss
        case OnchainPayment
    }
    
    var currentMode = Mode.ScanAndProcess
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var scannerOverlay: UIView!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var enterManuallyLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var toLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    
    //Paying PR
    @IBOutlet weak var payingContainer: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var expirationDateLabel: UILabel!
    @IBOutlet weak var expirationLabel: UILabel!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var payingLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var payingContainerBottomConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var bottomContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomContainerHeightConstraint: NSLayoutConstraint!
    
    let prDecoder = PaymentRequestDecoder()
    
    var invoiceLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: invoiceLoading, loadingWheel: payingLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
            LoadingWheelHelper.toggleLoadingWheel(loading: invoiceLoading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(rootViewController : RootViewController? = nil) -> NewQRScannerViewController {
        let viewController = StoryboardScene.QRCodeScanner.newQrCodeScannerViewController.instantiate()
        viewController.rootViewController = rootViewController
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.isHidden = true
        confirmButton.layer.cornerRadius = confirmButton.frame.height/2
        addressField.delegate = self
        
        configureViewForMode()
    }
    
    func codeScanned(code: String) {
        if isProcessingPR() {
            return
        }
        
        PlayAudioHelper.playKeySound(soundId: PlayAudioHelper.VibrateSoundID)
        
        addressField.text = code
        confirmButton.isHidden = code == ""
        
        confirmButtonTouched()
    }
    
    func configureViewForMode() {
        closeButton.isHidden = false
        backButton.isHidden = true
        enterManuallyLabel.isHidden = false
        bottomContainerBottomConstraint.constant = 0
        
        switch (currentMode) {
        case Mode.ScanAndProcess:
            setLabels(title: "scan.qr.code.upper".localized, placeHolder: "paste.invoice.subscription".localized, buttonTitle: "verify".localized)
            break
        case Mode.DirectPayment:
            setLabels(title: "contact.address.upper".localized, placeHolder: "enter.address".localized, buttonTitle: "confirm".localized)
            toLabel.isHidden = false
            toLabelWidthConstraint.constant = 43
            break
        case Mode.ScanAndDismiss:
            setLabels(title: "scan.upper".localized, placeHolder: "enter.code".localized, buttonTitle: "confirm".localized)
            setCompleteScannerView()
            break
        case Mode.OnchainPayment:
            setLabels(title: "scan.btc".localized, placeHolder: "enter.btc".localized, buttonTitle: "confirm".localized)
            break
        }
        
        bottomContainer.superview?.layoutIfNeeded()
        toLabel.superview?.layoutIfNeeded()
    }
    
    func setCompleteScannerView() {
        toLabel.isHidden = true
        toLabelWidthConstraint.constant = 0
        enterManuallyLabel.isHidden = true
        bottomContainerBottomConstraint.constant = -250
    }
    
    func setLabels(title: String, placeHolder: String, buttonTitle: String) {
        viewTitle.text = title
        addressField.placeholder = placeHolder
        confirmButton.setTitle(buttonTitle.uppercased(), for: .normal)
        viewTitle.addTextSpacing(value: 2)
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
            
            bottomContainerBottomConstraint.constant = keyboardSize.height
            bottomContainerHeightConstraint.constant = 60
            
            UIView.animate(withDuration: duration, delay: 0.0, options: UIView.AnimationOptions(rawValue: curve), animations: {
                self.bottomContainer.superview?.layoutIfNeeded()
                self.enterManuallyLabel.alpha = 0.0
                self.scannerOverlay.alpha = 0.0
                self.confirmButton.alpha = 0.0
            }, completion: nil)
        }
    }
    
    @objc override func keyboardWillHide(_ notification: Notification) {
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
        
        bottomContainerBottomConstraint.constant = 0
        bottomContainerHeightConstraint.constant = 200
        
        UIView.animate(withDuration: duration, delay: 0.0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.bottomContainer.superview?.layoutIfNeeded()
            self.enterManuallyLabel.alpha = 1.0
            self.scannerOverlay.alpha = 1.0
            self.confirmButton.alpha = 1.0
        }, completion: nil)
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmButtonTouched() {
        if let code = addressField.text {
            let fixedCode = code.fixInvoiceString().trim()
            confirmButton.isHidden = fixedCode == ""
            
            if currentMode == .ScanAndProcess {
                validateQRString(string: fixedCode)
            } else {
                delegate?.didScanQRCode?(string: code)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func shouldShowAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.navigationController?.present(alert, animated: true, completion: nil)
    }
}

extension NewQRScannerViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString
        let emptyString = currentString == ""
        self.confirmButton.isHidden = emptyString
        return true
    }
}
