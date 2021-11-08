// PodcastEpisode+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


@objc(PodcastEpisode)
public class PodcastEpisode: NSManagedObject {
    
}

extension PodcastEpisode {
    
    func isAvailable() -> Bool {
        return ConnectivityHelper.isConnectedToInternet || self.isDownloaded
    }
    
    func getAudioUrl() -> URL? {
        if self.isDownloaded {
            if let fileName = URL(string: urlPath ?? "")?.lastPathComponent {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: path.path) {
                    return path
                }
            }
        }
        guard let episodeUrl = urlPath, !episodeUrl.isEmpty else {
            return nil
        }
        return URL(string: episodeUrl)
    }
    
    func shouldDeleteFile(deleteCompletion: @escaping () -> ()) {
        if self.isDownloaded {
            if let fileName = URL(string: urlPath ?? "")?.lastPathComponent {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
                
                if FileManager.default.fileExists(atPath: path.path) {
                    try? FileManager.default.removeItem(at: path)
                    self.isDownloaded = false
                    deleteCompletion()
                }
            }
        }
    }
}
