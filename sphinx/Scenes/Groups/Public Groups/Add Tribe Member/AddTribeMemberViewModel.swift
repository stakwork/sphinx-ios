//
//  AddTribeMemberViewModel.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/08/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class AddTribeMemberViewModel : NSObject {
    
    init(vc: AddTribeMemberViewController) {
        self.vc = vc
    }
    
    struct TribeMemberInfo {
        var alias : String? = nil
        var img : String? = nil
        var contactKey : String? = nil
        var publickey : String? = nil
        var routeHint : String? = nil
    }
    
    public enum MemberFields: Int {
        case Alias
        case Image
        case PublicKey
        case RouteHint
        case ContactKey
    }
    
    var vc: AddTribeMemberViewController
    var memberInfo = TribeMemberInfo()
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    var shouldUploadImage = false
    
    func isMemberInfoValid() -> Bool {
        guard let alias = memberInfo.alias, let publicKey = memberInfo.publickey, let contactKey = memberInfo.contactKey else {
            return false
        }
        
        let routeHint = memberInfo.routeHint ?? ""
        let validRouteHint = routeHint.isEmpty || routeHint.isRouteHint
        
        return (
            !alias.isEmpty &&
            (!publicKey.isEmpty && publicKey.isPubKey) &&
            !contactKey.isEmpty &&
            validRouteHint
        )
    }
    
    func completeValue(textField: UITextField) {
        switch (textField.tag) {
        case MemberFields.Alias.rawValue:
            memberInfo.alias = textField.text ?? ""
            break
        case MemberFields.PublicKey.rawValue:
            memberInfo.publickey = textField.text ?? ""
            break
        case MemberFields.RouteHint.rawValue:
            memberInfo.routeHint = textField.text ?? ""
            break
        case MemberFields.ContactKey.rawValue:
            memberInfo.contactKey = textField.text ?? ""
        default:
            break
        }
    }
    
    func completeImageUrl(imageUrl: String) {
        memberInfo.img = imageUrl
    }
    
    func showImagePicker() {
        imagePickerManager.configurePicker(vc: vc)
        imagePickerManager.showAlert(title: "tribe.member.image".localized, message: "select.option".localized, sourceView: vc.memberImageView)
    }
    
    func getMemberParams() -> [String: AnyObject] {
        var parameters = [String : AnyObject]()
        
        parameters["chat_id"] = vc.chat.id as AnyObject
        
        if let alias = memberInfo.alias  as? AnyObject {
            parameters["alias"] = alias
        }
        
        if let image = memberInfo.img  as? AnyObject {
            parameters["photo_url"] = image
        }
        
        if let publicKey = memberInfo.publickey  as? AnyObject {
            parameters["pub_key"] = publicKey
        }
        
        if let routeHint = memberInfo.routeHint  as? AnyObject {
            parameters["route_hint"] = routeHint
        }
        
        if let contactKey = memberInfo.contactKey  as? AnyObject {
            parameters["contact_key"] = contactKey
        }
        
        
        return parameters
    }
    
    func addMember() {
        vc.uploadingPhoto = false
        vc.loading = true
        
        let params = getMemberParams()

        API.sharedInstance.addTribeMember(params: params, callback: { _ in
            self.vc.dismissOnSuccess()
        }, errorCallback: {
            self.vc.showErrorAlert()
        })
    }
    
    func uploadImage(image: UIImage?) {
        if let imgData = image?.jpegData(compressionQuality: 0.5), shouldUploadImage {
            vc.uploadingPhoto = true
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.setDelegate(delegate: self)
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadImage(attachmentObject: attachmentObject, route: "public")
        } else {
            addMember()
        }
    }
}

extension AddTribeMemberViewModel : AttachmentsManagerDelegate {
    func didSuccessUploadingImage(url: String) {
        completeImageUrl(imageUrl: url)
        addMember()
    }
}
