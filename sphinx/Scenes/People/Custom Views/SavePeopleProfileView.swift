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
    
    private func showAlertAndDismiss(_ error: String) {
        messageBubbleHelper.showGenericMessageView(text: error, delay: 5, textColor: UIColor.white, backColor: UIColor.Sphinx.BadgeRed, backAlpha: 1.0)
        delegate?.shouldDismissVC()
    }
    
    override func modalDidShow() {
        super.modalDidShow()
        
        loading = true
        
        guard let host = authInfo?.host, let key = authInfo?.key, !host.isEmpty && !key.isEmpty else {
            showAlertAndDismiss("people.save-failed".localized)
            return
        }
        
        API.sharedInstance.getProfileByKey(host: host, key: key, callback: { (success, json) in
            guard let json = json, success else {
                self.showAlertAndDismiss("people.save-failed".localized)
                return
            }
            
            let path = json["path"].string
            let method = json["method"].string
            let profile = JSON(json["body"].dictionaryValue)
            
            guard path == "profile" else {
                self.showAlertAndDismiss("people.save-failed".localized)
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
        parameters["tags"] = authInfo?.personInfo["tags"].arrayValue as AnyObject
        parameters["price_to_meet"] = authInfo?.personInfo["price_to_meet"].intValue as AnyObject
        parameters["extras"] = authInfo?.personInfo["extras"].dictionaryValue as AnyObject
        
        API.sharedInstance.savePeopleProfile(
            params: parameters,
            callback: { success in
                
            if success {
                self.showAlertAndDismiss("people.save-succeed".localized)
            } else {
                self.showAlertAndDismiss("people.save-failed".localized)
            }
        })
    }
    
    private func deleteProfile() {
        API.sharedInstance.deletePeopleProfile(callback: { success in
            if success {
                self.showAlertAndDismiss("people.delete-succeed".localized)
            } else {
                self.showAlertAndDismiss("people.delete-failed".localized)
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
