//
//  APIUsersExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    
    var lastSeenContactsDate: Date? {
        get {
            return UserDefaults.Keys.lastSeenContactsDate.get(defaultValue: nil)
        }
        set {
            UserDefaults.Keys.lastSeenContactsDate.set(newValue)
        }
    }
    
    func getContacts(fromPush: Bool = false, callback: @escaping ContactsResultsCallback){
        guard let request = getURLRequest(route: "/contacts?from_group=false", method: "GET") else {
            callback([], [], [])
            return
        }
        let requestType: CancellableRequestType? = fromPush ? nil : .contacts
        cancellableRequest(request, type: requestType) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let jsonResponse = JSON(response)
                        let contactsArray = JSON(jsonResponse["contacts"]).arrayValue
                        let chatsArray = JSON(jsonResponse["chats"]).arrayValue
                        let subscriptionsArray = JSON(jsonResponse["subscriptions"]).arrayValue
                        
                        if contactsArray.count > 0 || chatsArray.count > 0 {
                            self.cancellableRequest = nil
                            callback(contactsArray, chatsArray, subscriptionsArray)
                            return
                        }
                    }
                }
                self.cancellableRequest = nil
                callback([], [], [])
            case .failure(_):
                self.cancellableRequest = nil
                callback([], [], [])
            }
        }
    }
    
    func getLatestContacts(
        page: Int,
        date: Date,
        nextPageCallback: @escaping LatestContactsResultsCallback,
        callback: @escaping LatestContactsResultsCallback
    ){
        let itemsPerPage = 1000
        var route = "/latest_contacts"
        let offset = (page - 1) * itemsPerPage
        let limit = itemsPerPage
        
        let lastSeenDate = lastSeenContactsDate ?? Date(timeIntervalSince1970: 0)
        if let dateString = lastSeenDate.getStringFromDate(format:"yyyy-MM-dd HH:mm:ss").percentEscaped {
            route = "\(route)?date=\(dateString)&offset=\(offset)&limit=\(limit)"
        }
        
        guard let request = getURLRequest(route: route, method: "GET") else {
            callback([], [], [], [])
            return
        }
        
        cancellableRequest(request, type: .contacts) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let jsonResponse = JSON(response)
                        
                        let contactsArray = JSON(jsonResponse["contacts"]).arrayValue
                        let invitesArray = JSON(jsonResponse["invites"]).arrayValue
                        let chatsArray = JSON(jsonResponse["chats"]).arrayValue
                        let subscriptionsArray = JSON(jsonResponse["subscriptions"]).arrayValue
                        
                        if contactsArray.count > 0 || chatsArray.count > 0 || invitesArray.count > 0 || subscriptionsArray.count > 0 {
                            
                            self.cancellableRequest = nil
                            
                            if contactsArray.count == itemsPerPage || chatsArray.count == itemsPerPage {
                                nextPageCallback(contactsArray, chatsArray, subscriptionsArray, invitesArray)
                            } else {
                                self.lastSeenContactsDate = date
                                
                                callback(contactsArray, chatsArray, subscriptionsArray, invitesArray)
                            }
                            
                            return
                        }
                    }
                }
                self.cancellableRequest = nil
                callback([], [], [], [])
            case .failure(_):
                self.cancellableRequest = nil
                callback([], [], [], [])
            }
        }
    }
    
    func getContactsForChat(chatId: Int, callback: @escaping ChatContactsCallback){
        guard let request = getURLRequest(route: "/contacts/\(chatId)", method: "GET") else {
            callback([])
            return
        }
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let jsonResponse = JSON(response)
                        let contactsArray = JSON(jsonResponse["contacts"]).arrayValue
                        callback(contactsArray)
                        return
                    }
                }
                callback([])
            case .failure(_):
                callback([])
            }
        }
    }
    
    func updateUser(id: Int, params: [String: AnyObject], callback: @escaping UpdateUserCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/contacts/\(id)", params: params as NSDictionary?, method: "PUT") else {
            callback([])
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let contact = JSON(response)
                        callback(contact)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func createContact(params: [String: AnyObject], callback: @escaping UpdateUserCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/contacts", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let contact = JSON(response)
                        callback(contact)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func exchangeKeys(id: Int, callback: @escaping UpdateUserCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/contacts/\(id)/keys", method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let contact = JSON(response)
                        callback(contact)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func deleteContact(id: Int, callback: @escaping SuccessCallback) {
        guard let request = getURLRequest(route: "/contacts/\(id)", method: "DELETE") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            case .failure(_):
                callback(false)
            }
        }
    }
    
    public enum ToggleBlockRoute: Int {
        case Block
        case Unblock
    }
    
    public func blockContact(
        id: Int,
        callback: @escaping UpdateUserCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        
        self.toggleBlockContact(
            id: id,
            route: .Block,
            callback: callback,
            errorCallback: errorCallback
        )
    }
    
    public func unblockContact(
        id: Int,
        callback: @escaping UpdateUserCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        
        self.toggleBlockContact(
            id: id,
            route: .Unblock,
            callback: callback,
            errorCallback: errorCallback
        )
    }
    
    public func toggleBlockContact(
        id: Int,
        route: ToggleBlockRoute,
        callback: @escaping UpdateUserCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        
        let routeString = (route == .Block) ? "block" : "unblock"
        
        guard let request = getURLRequest(route: "/\(routeString)/\(id)", method: "PUT") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                       let response = json["response"], success {
                        
                        callback(JSON(response))
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func checkRoute(chat: Chat?, contact: UserContact?, callback: @escaping SuccessCallback) {
        if (chat?.isPrivateGroup() ?? false) || (chat?.isMyPublicGroup() ?? false) {
            callback(true)
            return
        }
        
        guard let route = getRouteForCheckRoute(chat: chat, contact: contact) else {
            callback(true)
            return
        }

        guard let request = getURLRequest(route: route, method: "GET") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let response = JSON(response)
                        if let successProb = response["success_prob"].double, successProb > 0 {
                            callback(true)
                            return
                        }
                    }
                }
                callback(false)
            case .failure(_):
                callback(false)
            }
        }
    }
    
    private func getRouteForCheckRoute(chat: Chat?, contact: UserContact?) -> String? {
        let routeContact = contact ?? chat?.getContactForRouteCheck()
        if let routeContact = routeContact, let pubkey = routeContact.publicKey {
            return "/route?pubkey=\(pubkey)&route_hint=\(routeContact.routeHint ?? "")"
        } else if let chat = chat {
            return "/route2?chat_id=\(chat.id)"
        }
        return nil
    }
    
    public func uploadImage(userId: Int? = nil, chatId: Int? = nil, image: UIImage, progressCallback: @escaping UploadProgressCallback, callback: @escaping UploadCallback) {
        guard let imgData = image.jpegData(compressionQuality: 0.5) else {
            callback(false, nil)
            return
        }
        
        let method = HTTPMethod(rawValue: "POST")
        let ip = UserData.sharedInstance.getNodeIP()
        let url = API.getUrl(route: "\(ip)/upload")
        var parameters: [String: String] = [:]
        
        if let userId = userId {
            parameters["contact_id"] = "\(userId)"
        } else if let chatId = chatId {
            parameters["chat_id"] = "\(chatId)"
        }
        
        var httpHeaders = HTTPHeaders()
        let headers = UserData.sharedInstance.getAuthenticationHeader()
        
        for (key, value) in headers {
            httpHeaders.add(name: key, value: value)
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
            }
            multipartFormData.append(imgData, withName: "file", fileName: "file.jpg", mimeType: "image/jpg")
        }, to: url, method: method, headers: httpHeaders).uploadProgress(queue: .main, closure: { progress in
            let progressInt = Int(round(progress.fractionCompleted * 100))
            progressCallback(progressInt)
        }).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let fileURL = json["photo_url"] as? String, success {
                        callback(true, fileURL)
                        return
                    }
                }
                callback(false, nil)
            case .failure(_):
                callback(false, nil)
            }
        }
    }
}
