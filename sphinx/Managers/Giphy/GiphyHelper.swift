//
//  GiphyHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import GiphyUISDK
import SwiftyJSON

class GiphyHelper {
    
    public static let kPrefix = "giphy::"
    
    public static func getMobileURL(url: String) -> String {
        return url.replacingOccurrences(of: "giphy.gif", with: "200w.gif")
    }
    
    public static func getJSONObjectFrom(message: String) -> JSON? {
        if message.starts(with: GiphyHelper.kPrefix) {
            if let stringWithoutPrefix = message.replacingOccurrences(of: GiphyHelper.kPrefix, with: "").base64Decoded {
                if let data = stringWithoutPrefix.data(using: .utf8) {
                    if let jsonObject = try? JSON(data: data) {
                        return jsonObject
                    }
                }
            }
        }
        return nil
    }
    
    public static func getAspectRatioFrom(message: String) -> Double {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            let aspectRatio = jsonObject["aspect_ratio"].doubleValue
            return (aspectRatio > 0) ? aspectRatio : 1.0
        }
        return 1.0
    }
    
    public static func getUrlFrom(message: String, mobile: Bool = true) -> String? {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            if let url = jsonObject["url"].string {
                return mobile ? getMobileURL(url: url) : url
            }
        }
        return nil
    }
    
    public static func getMessageFrom(message: String) -> String? {
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: message) {
            if let message = jsonObject["text"].string, !message.isEmpty {
                return message
            } else {
                return ""
            }
        }
        return nil
    }
    
    public static func getGiphyDataFrom(url: String, messageId: Int, completion: @escaping (Data?, Int) -> ()) {
        if let data = MediaLoader.getMediaDataFromCachedUrl(url: url) {
            completion(data, messageId)
            return
        }
        
        GPHCache.shared.downloadAssetData(url) { (data, error) in
            if let data = data {
                MediaLoader.storeMediaDataInCache(data: data, url: url)
                
                DispatchQueue.main.async {
                    completion(data, messageId)
                }
            } else {
                completion(nil, messageId)
            }
        }
    }
    
    func getGiphyVC(darkMode: Bool, delegate: GiphyDelegate) -> GiphyViewController {
        GiphyViewController.trayHeightMultiplier = 0.55
        
        let giphy = GiphyViewController()
        giphy.mediaTypeConfig = [.gifs, .stickers, .recents]
        giphy.theme = GPHTheme(type: darkMode ? .darkBlur : .lightBlur)
        giphy.stickerColumnCount = GPHStickerColumnCount.three
        giphy.delegate = delegate
        
        return giphy
    }
    
    func getMessageStringFrom(media: GiphyUISDK.GPHMedia, text: String? = nil) -> String? {
        var json: [String: AnyObject] = [:]
        json["id"] = "\(media.id)" as AnyObject
        json["aspect_ratio"] = "\(media.aspectRatio)" as AnyObject
        json["text"] = text as AnyObject
        
        if let url = media.url(rendition: .original, fileType: .gif) {
            json["url"] = "\(url)" as AnyObject
        }
                
        if let strJson = JSON(json).rawString(), let base64 = strJson.base64Encoded {
            return "\(GiphyHelper.kPrefix)\(base64)"
        }
        return nil
    }
    
    func loadGiphyDataFrom(message: TransactionMessage, completion: @escaping (Data, Int) -> (), errorCompletion: @escaping (Int) -> ()) {
        let messageId = message.id
        let messageContent = message.messageContent ?? ""
        
        if let jsonObject = GiphyHelper.getJSONObjectFrom(message: messageContent) {
            if let url = jsonObject["url"].string {
                let mobileUrl = GiphyHelper.getMobileURL(url: url)
                
                GiphyHelper.getGiphyDataFrom(url: mobileUrl, messageId: messageId, completion: { (data, messageId) in
                    DispatchQueue.main.async {
                        if let data = data {
                            completion(data, messageId)
                        } else {
                           errorCompletion(messageId)
                        }
                    }
                })
                return
            }
        }
        errorCompletion(messageId)
    }
}
