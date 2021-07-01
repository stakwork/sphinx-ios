//
//  ShareInviteCodeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ShareInviteCodeViewController: UIViewController {
    
    var qrCodeString = ""
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var inviteCodeLabel: UILabel!
    @IBOutlet weak var tapToCopyIcon: UIImageView!
    @IBOutlet weak var shareIcon: UIImageView!
    
    static func instantiate() -> ShareInviteCodeViewController {
        let viewController = StoryboardScene.Invite.shareInviteCodeViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTitle.addTextSpacing(value: 2)
        tapToCopyIcon.tintColorDidChange()
        shareIcon.tintColorDidChange()
        
        if qrCodeString != "" {
            qrCodeImageView.image = UIImage.qrCode(from: qrCodeString)
            inviteCodeLabel.text = qrCodeString
        }
    }
    
    @IBAction func copyButtonTouched() {
        if let code = inviteCodeLabel.text {
            ClipboardHelper.copyToClipboard(text: code, message: "code.copied.clipboard".localized)
        }
    }
    
    @IBAction func refreshCodeButtonTouched() {
    }
    
    @IBAction func shareButtonTouched() {
        if qrCodeString == "" {
            return
        }
        
        let items: [Any] = [qrCodeString]
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true, completion: nil)
    }
}
