//
//  PeopleTorActionsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/11/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class PeopleTorActionsView: CommonModalView {

    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadingWheelContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let kSaveRequestMethod = "POST"
    let kDeleteRequestMethod = "DELETE"
    
    let kSaveProfilePath = "profile"
    let kClaimOnLiquidPath = "claim_on_liquid"
    
    var loading = false {
        didSet {
            loadingWheelContainer.alpha = loading ? 1.0 : 0.0
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: self)
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
    
    private func setup() {
        Bundle.main.loadNibNamed("PeopleTorActionsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.layer.cornerRadius = 15
        
        saveButton.layer.cornerRadius = saveButton.frame.height / 2
        saveButton.addShadow(location: .bottom, opacity: 0.3, radius: 5)
    }
    
    override func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        super.modalWillShowWith(query: query, delegate: delegate)
        
        processQuery()
        
        hostLabel.text = "\(authInfo?.host ?? "...")?"
    }
    
    private func showErrorAlertAndDismiss(_ error: String) {
        messageBubbleHelper.showGenericMessageView(text: error, textColor: UIColor.white, backColor: UIColor.Sphinx.BadgeRed, backAlpha: 1.0)
        
        DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
            self.delegate?.shouldDismissVC()
        })
    }
    
    private func showAlertAndDismiss(_ message: String) {
        messageBubbleHelper.showGenericMessageView(text: message)
        
        DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
            self.delegate?.shouldDismissVC()
        })
    }
    
    override func modalDidShow() {
        super.modalDidShow()
        
        loading = true
        
        guard let host = authInfo?.host, let key = authInfo?.key, !host.isEmpty && !key.isEmpty else {
            showErrorAlertAndDismiss("people.save-failed".localized)
            return
        }
        
        API.sharedInstance.getExternalRequestByKey(host: host, key: key, callback: { (success, json) in
            
            guard let json = json, success else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            let path = json["path"].string
            let method = json["method"].string
            let body = JSON.init(parseJSON: json["body"].stringValue)
            
            self.authInfo?.jsonBody = body
            self.authInfo?.updateMethod = method
            self.authInfo?.path = path
            
            switch(path) {
            case self.kSaveProfilePath:
                switch (method) {
                case self.kSaveRequestMethod:
                    self.presentSaveModal()
                case self.kDeleteRequestMethod:
                    self.presentDeleteModal()
                default:
                    break
                }
            case self.kClaimOnLiquidPath:
                self.presentClaimOnLiquidModal()
            default:
                break
            }
        })
    }
    
    private func setDefaultModalInfo() {
        loading = false
        hostLabel.text = authInfo?.host ?? ""
    }
    
    private func presentSaveModal() {
        setDefaultModalInfo()
        
        viewTitleLabel.text = "people.save-profile".localized
    }
    
    private func presentDeleteModal() {
        setDefaultModalInfo()
        
        viewTitleLabel.text = "people.delete-profile".localized
    }
    
    private func presentClaimOnLiquidModal() {
        setDefaultModalInfo()
        
        viewTitleLabel.text = "people.claim-on-liquid".localized
    }
    
    private func saveProfile() {
        var parameters = [String : AnyObject]()
        parameters["id"] = authInfo?.jsonBody["id"].intValue as AnyObject
        parameters["host"] = authInfo?.jsonBody["host"].stringValue as AnyObject
        parameters["owner_alias"] = authInfo?.jsonBody["owner_alias"].stringValue as AnyObject
        parameters["description"] = authInfo?.jsonBody["description"].stringValue as AnyObject
        parameters["img"] = authInfo?.jsonBody["img"].stringValue as AnyObject
        parameters["price_to_meet"] = authInfo?.jsonBody["price_to_meet"].intValue as AnyObject
        parameters["tags"] = (authInfo?.jsonBody["tags"].arrayValue as NSArray?) as AnyObject
        
        if let tags = authInfo?.jsonBody["tags"].arrayValue as NSArray? {
            parameters["tags"] = tags as AnyObject
        }
        
        if let extras = authInfo?.jsonBody["extras"].dictionaryObject as NSDictionary? {
            parameters["extras"] = extras as AnyObject
        }
        
        API.sharedInstance.savePeopleProfile(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.save-succeed".localized)
            } else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
            }
        })
    }
    
    private func deleteProfile() {
        var parameters = [String : AnyObject]()
        parameters["id"] = authInfo?.jsonBody["id"].intValue as AnyObject
        parameters["host"] = authInfo?.jsonBody["host"].stringValue as AnyObject
        
        API.sharedInstance.deletePeopleProfile(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.delete-succeed".localized)
            } else {
                self.showErrorAlertAndDismiss("people.delete-failed".localized)
            }
        })
    }
    
    private func redeemBadgeTokens() {
        var parameters = [String : AnyObject]()
        parameters["host"] = authInfo?.jsonBody["host"].stringValue as AnyObject
        parameters["amount"] = authInfo?.jsonBody["amount"].intValue as AnyObject
        parameters["to"] = authInfo?.jsonBody["to"].stringValue as AnyObject
        parameters["asset"] = authInfo?.jsonBody["asset"].intValue as AnyObject
        parameters["memo"] = authInfo?.jsonBody["memo"].stringValue as AnyObject
        
        API.sharedInstance.redeemBadgeTokens(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.claim-on-liquid-succeed".localized)
            } else {
                self.showErrorAlertAndDismiss("people.claim-on-liquid-failed".localized)
            }
        })
    }

    @IBAction func saveButtonTouched() {
        buttonLoading = true
        
        if let path = authInfo?.path {
            if let method = authInfo?.updateMethod {
                switch(path) {
                case self.kSaveProfilePath:
                    switch (method) {
                    case self.kSaveRequestMethod:
                        self.saveProfile()
                    case self.kDeleteRequestMethod:
                        self.deleteProfile()
                    default:
                        break
                    }
                case self.kClaimOnLiquidPath:
                    self.redeemBadgeTokens()
                default:
                    break
                }
            }
        }
    }
    
}
