//
//  SavePeopleProfileView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/11/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class SavePeopleProfileView: CommonModalView {

    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadingWheelContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let kSaveRequestMethod = "POST"
    let kDeleteRequestMethod = "DELETE"
    
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
        Bundle.main.loadNibNamed("SavePeopleProfileView", owner: self, options: nil)
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
        
        API.sharedInstance.getProfileByKey(host: host, key: key, callback: { (success, json) in
            guard let json = json, success else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            let path = json["path"].string
            let method = json["method"].string
            let profile = JSON.init(parseJSON: json["body"].stringValue)
            
            guard path == "profile" else {
                self.showErrorAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            self.authInfo?.personInfo = profile
            self.authInfo?.updateMethod = method
            
            switch (method) {
            case self.kSaveRequestMethod:
                self.presentSaveModal()
            case self.kDeleteRequestMethod:
                self.presentDeleteModal()
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
    
    private func saveProfile() {
        var parameters = [String : AnyObject]()
        parameters["id"] = authInfo?.personInfo["id"].intValue as AnyObject
        parameters["host"] = authInfo?.personInfo["host"].stringValue as AnyObject
        parameters["owner_alias"] = authInfo?.personInfo["owner_alias"].stringValue as AnyObject
        parameters["description"] = authInfo?.personInfo["description"].stringValue as AnyObject
        parameters["img"] = authInfo?.personInfo["img"].stringValue as AnyObject
        parameters["price_to_meet"] = authInfo?.personInfo["price_to_meet"].intValue as AnyObject
        parameters["tags"] = (authInfo?.personInfo["tags"].arrayValue as NSArray?) as AnyObject
        
        if let tags = authInfo?.personInfo["tags"].arrayValue as NSArray? {
            parameters["tags"] = tags as AnyObject
        }
        
        if let extras = authInfo?.personInfo["extras"].dictionaryObject as NSDictionary? {
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
        parameters["id"] = authInfo?.personInfo["id"].intValue as AnyObject
        parameters["host"] = authInfo?.personInfo["host"].stringValue as AnyObject
        
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

    @IBAction func saveButtonTouched() {
        buttonLoading = true
        
        if let method = authInfo?.updateMethod {
            buttonLoading = true
            
            switch (method) {
            case kSaveRequestMethod:
                self.saveProfile()
            case kDeleteRequestMethod:
                self.deleteProfile()
            default:
                break
            }
        }
    }
    
}
