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
    
    func requestToCacheVideoRemotely(
        for videoIDs: [String],
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ){

        let videoURLPaths = getYoutubeVideoURLPaths(videoIDs: videoIDs)
        var requestPath = API.getUrl(route: "\(API.kTribesServerBaseURL)/feed/download")
        let params = [
            "youtube_urls" : videoURLPaths
        ]
        
        guard let request = createRequest(requestPath.percentEscaped ?? requestPath, bodyParams: params as NSDictionary, method: "POST") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { response in
            switch response.result {
            case .success(let data):
                print(data)
                callback()
            case .failure(let error):
                print(error)
                errorCallback()
            }
        }
        
    }
    
    func getFullCachedFilePath(partialPath:String)->String{
        let convertedPath = partialPath.replacingOccurrences(of: ".mp3", with: ".mp4")
        return "https://stakwork-uploads.s3.amazonaws.com/" + convertedPath
    }
    
    func getYoutubeVideoURLPaths(videoIDs:[String])->[String]{
        var videoURLsArray = [String]()
        for id in videoIDs{
            videoURLsArray.append("https://www.youtube.com/watch?v=\(id)")
        }
        return videoURLsArray
    }
    
    func getRemoteVideoCachePath(videoID:String)->String{
        return "https://knowledge-graph.sphinx.chat/video?id=\(videoID)"//"https://knowledge-graph.sphinx.chat/video?id=\(videoID)/"
    }
    
    func getVideoRemoteStorageStatus(
        videoID:String,
        callback: @escaping VideoFileExistsCallback,
        errorCallback: @escaping EmptyCallback
    ){
        let urlPath = getRemoteVideoCachePath(videoID: videoID)
        
        guard let url = URL(string: urlPath) else{
            errorCallback()
            return
        }
        
        getFileStatusAndLocation(url: url, completion: { status, location in
            if let status = status,
               status.lowercased()  == "completed" ,
            let validPartialPath = location{
                callback(self.getFullCachedFilePath(partialPath: validPartialPath))
            }
            else{
                callback(nil)
            }
        })
    }
    
    func getFileStatusAndLocation(url: URL, completion: @escaping (String?, String?) -> Void) {
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(nil, nil)
                return
            }
            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonDict = json as? [String: Any],
                       let dataDict = jsonDict["data"] as? [String: Any],
                       let status = dataDict["status"] as? String,
                       let finalDestination = dataDict["finalDestination"] as? String {
                        completion(status, finalDestination)
                        return
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            completion(nil, nil)
        }
        
        task.resume()
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
