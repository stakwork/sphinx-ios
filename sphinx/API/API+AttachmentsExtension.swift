//
//  APIAttachmentsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    public func askAuthentication(callback: @escaping AskAuthenticationCallback) {
        let url = "\(API.kAttachmentsServerUrl)/ask"
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
            callback(nil, nil)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let id = json["id"] as? String, let challenge = json["challenge"] as? String {
                        callback(id, challenge)
                    } else {
                        callback(nil, nil)
                    }
                }
            case .failure(_):
                callback(nil, nil)
            }
        }
    }
    
    public func verifyAuthentication(
        id: String,
        sig: String,
        pubkey: String,
        callback: @escaping VerifyAuthenticationCallback
    ) {
        let url = "\(API.kAttachmentsServerUrl)/verify?id=\(id)&sig=\(sig)&pubkey=\(pubkey)"
        
        guard let request = createRequest(url, bodyParams: nil, method: "POST", contentType: "multipart/form-data") else {
            callback(nil)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let token = json["token"] as? String {
                        callback(token)
                    } else {
                        callback(nil)
                    }
                }
            case .failure(_):
                callback(nil)
            }
        }
    }
    
    public func getMediaItemInfo(message: TransactionMessage, token: String, callback: @escaping MediaInfoCallback) {
        guard let muid = message.muid, !muid.isEmpty else {
            callback(message.id, nil, nil)
            return
        }
        
        let url = "\(API.kAttachmentsServerUrl)/media/\(muid)"
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET", token: token) else {
            callback(message.id, nil, nil)
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let jsonData = JSON(data)
                
                if let fileName = jsonData["filename"].string, let fileSize = jsonData["size"].int {
                    callback(message.id, fileName, fileSize)
                } else {
                    callback(message.id, nil, nil)
                }
            case .failure(_):
                callback(message.id, nil, nil)
            }
        }
    }
    
    public func uploadData(attachmentObject: AttachmentObject, route:String = "file", token: String, progressCallback: @escaping UploadProgressCallback, callback: @escaping UploadAttachmentCallback) {
        let method = HTTPMethod(rawValue: "POST")
        let url = "\(API.kAttachmentsServerUrl)/\(route)"
        
        var parameters: [String: String] = [String: String]()
        parameters["name"] = attachmentObject.getNameParam()
        
        let headers = HTTPHeaders(["Authorization": "Bearer \(token)"])
        
        cancelUploadRequest()
        
        uploadRequest = AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            let fileAndMime = attachmentObject.getFileAndMime()
            multipartFormData.append(attachmentObject.data, withName: "file", fileName: fileAndMime.0, mimeType: fileAndMime.1)
        }, to: url, method: method, headers: headers).uploadProgress(queue: .main, closure: { progress in
            let progressInt = Int(round(progress.fractionCompleted * 100))
            progressCallback(progressInt)
        }).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    callback(true, json)
                    return
                }
                callback(false, nil)
            case .failure(_):
                callback(false, nil)
            }
        }
    }
    
    public func cancelUploadRequest() {
        if let uploadRequest = uploadRequest {
            uploadRequest.cancel()
            self.uploadRequest = nil
        }
    }
    
    public func sendAttachment(
        params: [String : AnyObject],
        callback: @escaping MessageObjectCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(route: "/attachment", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func payAttachment(params: [String : AnyObject], callback: @escaping MessageObjectCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/purchase", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func getPaymentTemplates(token: String, callback: @escaping TemplatesCallback, errorCallback: @escaping EmptyCallback) {
        let url = "\(API.kAttachmentsServerUrl)/templates"
        
        guard let request = createRequest(url, bodyParams: nil, method: "GET", token: token) else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let templatesArray = JSON(data).arrayValue
                var templatesImages = [ImageTemplate]()
                
                for template in templatesArray {
                    templatesImages.append(ImageTemplate(muid: template["muid"].stringValue, width: template["width"].intValue, height: template["height"].intValue))
                }
                callback(templatesImages)
            case .failure(_):
                errorCallback()
            }
        }
    }
}
