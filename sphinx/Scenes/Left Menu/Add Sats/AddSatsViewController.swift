//
//  AddSatsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class AddSatsViewController: UIViewController {

    var rootViewController : RootViewController!

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var appButtonContainer: UIView!
    @IBOutlet weak var appImage: UIImageView!
    @IBOutlet weak var appName: UILabel!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var loading = false {
        didSet {
            loadingContainer.isHidden = !loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: self.view, views: [])
        }
    }
    
    var copyButtonEnable = true {
        didSet {
            copyButton.setTitle((copyButtonEnable ? "copy" : "copied").localized, for: .normal)
            copyButton.setTitleColor(copyButtonEnable ? UIColor.white : UIColor.Sphinx.SecondaryText, for: .normal)
            copyButton.backgroundColor = copyButtonEnable ? UIColor.Sphinx.PrimaryBlue : UIColor.Sphinx.WashedOutReceivedText
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appButtonContainer.layer.cornerRadius = 10
        appButtonContainer.layer.borderColor = UIColor.Sphinx.WashedOutReceivedText.resolvedCGColor(with: self.view)
        appButtonContainer.layer.borderWidth = 1
        
        appImage.layer.cornerRadius = 10
        
        copyButton.layer.cornerRadius = copyButton.frame.height / 2
        copyButton.clipsToBounds = true

        loading = true
        generateAddress()
    }
    
    func generateAddress() {
        API.sharedInstance.generateOnchainAddress(callback: { address in
            self.completeAddress(address)
        }, errorCallback: {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                self.closeButtonTouched()
            })
        })
    }
    
    func completeAddress(_ address: String) {
        addressLabel.text = address
        loading = false
    }
    
    static func instantiate(rootViewController : RootViewController) -> AddSatsViewController {
        let viewController = StoryboardScene.LeftMenu.addSatsViewController.instantiate()
        viewController.rootViewController = rootViewController
        return viewController
    }

    @IBAction func copyButtonTouched() {
        if let address = addressLabel.text, !address.isEmpty {
            ClipboardHelper.copyToClipboard(text: address, message: nil)
            copyButtonEnable = false
        }
    }
    
    @IBAction func openAppButtonTouched() {
        if let url = URL(string: "http://cash.app://") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true, completion: nil)
    }
}
