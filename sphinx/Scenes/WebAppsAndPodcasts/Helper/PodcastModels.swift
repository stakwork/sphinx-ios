//
//  PodcastModels.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

struct PodcastFeed {
    var chatId:Int? = nil
    var id:Int? = nil
    var title: String? = nil
    var description: String? = nil
    var author: String? = nil
    var image: String? = nil
    
    var model: PodcastModel? = nil
    var episodes: [PodcastEpisode] = []
    var destinations: [PodcastDestination] = []
}

class PodcastEpisode {
    var id:Int? = nil
    var title: String? = nil
    var description: String? = nil
    var url: String? = nil
    var image: String? = nil
    var link: String? = nil
    var downloaded: Bool = false
    
    func isAvailable() -> Bool {
        return ConnectivityHelper.isConnectedToInternet || self.downloaded
    }
    
    func getAudioUrl() -> URL? {
        if self.downloaded {
            if let fileName = URL(string: url ?? "")?.lastPathComponent {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: path.path) {
                    return path
                }
            }
        }
        guard let episodeUrl = url, !episodeUrl.isEmpty else {
            return nil
        }
        return URL(string: episodeUrl)
    }
    
    func shouldDeleteFile(deleteCompletion: @escaping () -> ()) {
        if self.downloaded && !ConnectivityHelper.isConnectedToInternet {
            if let fileName = URL(string: url ?? "")?.lastPathComponent {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: path.path) {
                    AlertHelper.showTwoOptionsAlert(title: "delete.episode.title".localized, message: "delete.episode.title".localized, confirm: {
                        try? FileManager.default.removeItem(at: path)
                        self.downloaded = false
                        deleteCompletion()
                    })
                }
            }
        }
    }
}

struct PodcastDestination {
    var address: String? = nil
    var split: Double? = nil
    var type: String? = nil
}

struct PodcastModel {
    var type: String? = nil
    var suggested: Double? = nil
    var suggestedSats: Int? = nil
}

struct PodcastComment {
    var feedId:Int? = nil
    var itemId:Int? = nil
    var timestamp:Int? = nil
    var title: String? = nil
    var text: String? = nil
    var url: String? = nil
    var pubkey: String? = nil
    var uuid: String? = nil
    
    func getJsonString(withComment comment: String) -> String? {
        let pubkey = UserData.sharedInstance.getUserPubKey()
        var json: [String: AnyObject] = [:]
        if let feedId = feedId {
            json["feedID"] = feedId as AnyObject
        }
        if let itemId = itemId {
            json["itemID"] = itemId as AnyObject
        }
        if let timestamp = timestamp {
            json["ts"] = timestamp as AnyObject
        }
        if let title = title {
            json["title"] = "\(title)" as AnyObject
        }
        if let url = url {
            json["url"] = "\(url)" as AnyObject
        }
        if let pubkey = pubkey {
            json["pubkey"] = "\(pubkey)" as AnyObject
        }
        json["text"] = "\(comment)" as AnyObject
                
        if #available(iOS 13.0, *) {
            if let strJson = JSON(json).rawString(.utf8, options: .withoutEscapingSlashes) {
                return "\(PodcastPlayerHelper.kClipPrefix)\(strJson)"
            }
        } else {
            if let strJson = JSON(json).rawString() {
                return "\(PodcastPlayerHelper.kClipPrefix)\(strJson)"
            }
        }
        return nil
    }
}
