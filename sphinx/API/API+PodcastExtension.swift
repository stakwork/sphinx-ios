//
//  APIPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreData
import ObjectMapper

extension API {
    
    func getContentFeed(
        url: String,
        callback: @escaping ContentFeedCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = createRequest(url, bodyParams: nil, method: "GET") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { response in
            if let data = response.data {
                callback(JSON(data))
            } else {
                errorCallback()
            }
        }
    }
    
    
    func getPodcastInfo(podcastId: Int, callback: @escaping PodcastInfoCallback, errorCallback: @escaping EmptyCallback) {
        let url = API.getUrl(route: "https://tribes.sphinx.chat/podcast?id=\(podcastId)")
        let tribeRequest : URLRequest? = createRequest(url, bodyParams: nil, method: "GET")
        
        guard let request = tribeRequest else {
            errorCallback()
            return
        }
        
        //NEEDS TO BE CHANGED
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    callback(JSON(json))
                } else {
                    errorCallback()
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func streamSats(params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback:@escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/stream", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func updateChat(chatId: Int, params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback:@escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/chats/\(chatId)", params: params as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getAllContentFeedStatuses(
        persistingIn managedObjectContext: NSManagedObjectContext? = nil,
        callback: @escaping AllContentFeedStatusCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(route: "/content_feed_status", params: nil, method: "GET") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success,
                       let mapped_content_status = Mapper<ContentFeedStatus>().mapArray(JSONObject: json["response"]) {
                        
                        callback(mapped_content_status)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    
    func getContentFeedStatusFor(
        feedId: String,
        callback: @escaping ContentFeedStatusCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(route: "/content_feed_status/\(feedId)", params: nil, method: "GET") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success,
                       let mapped_content_status = Mapper<ContentFeedStatus>().map(JSONObject: json["response"]) {
                        
                        callback(mapped_content_status)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func saveContentFeedStatusesToRemote(
        params: [[String: Any]],
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        var requestParams : [String:Any] = [String:Any]()
        requestParams["contents"] = params
        
        guard let request = getURLRequest(route: "/content_feed_status", params: requestParams as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func saveContentFeedStatusToRemote(
        params: [String: Any],
        feedId: String,
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        var requestParams: [String: Any] = [String: Any]()
        requestParams["content"] = params
        
        guard let request = getURLRequest(route: "/content_feed_status/\(feedId)", params: requestParams as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getVideoRemoteStorageStatus(
        videoID:String,
        callback: @escaping VideoFileExistsCallback,
        errorCallback: @escaping EmptyCallback
    ){
        let urlPath = "https://stakwork-uploads.s3.amazonaws.com/uploads/customers/6040/media_to_local/00002e82-6911-4aea-a214-62c9d88740e0/\(videoID).mp4"
        
        guard let url = URL(string: urlPath) else{
            errorCallback()
            return
        }
        
        getFileSize(url: url, completion: { size in
            if let size = size,
               size > 100{
                callback(true)
            }
            else{
                callback(false)
            }
        })
    }
    
    func getFileSize(url: URL, completion: @escaping (Int64?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(nil)
                return
            }
            
            if let contentLengthString = httpResponse.allHeaderFields["Content-Length"] as? String,
               let contentLength = Int64(contentLengthString) {
                completion(contentLength)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }

}
