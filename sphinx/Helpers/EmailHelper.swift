//
//  EmailHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import MessageUI

class EmailHelper : NSObject {
    
    var emailBody: String
    
    init(emailBody: String) {
        self.emailBody = emailBody
    }
    
    func sendEmail(vc: UIViewController) -> MFMailComposeViewController? {
        var mail: MFMailComposeViewController?
        
        if MFMailComposeViewController.canSendMail() {
            mail = MFMailComposeViewController()
            if let vc = vc as? MFMailComposeViewControllerDelegate {
                mail?.mailComposeDelegate = vc
            }
            mail?.setSubject("Sphinx Support")
            mail?.setToRecipients(["support@stakwork.com"])
            mail?.setMessageBody(self.emailBody, isHTML: false)

            if let mail = mail {
                vc.present(mail, animated: true)
            }
        } else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "email.cant.be.sent".localized)
        }
        return mail
    }
}
