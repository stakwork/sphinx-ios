// PodcastEpisode+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import SwiftyJSON
import CoreData


extension PodcastEpisode {
    
    func isAvailable() -> Bool {
        return ConnectivityHelper.isConnectedToInternet || self.isDownloaded
    }
    
    func getAudioUrl() -> URL? {
        if let fileName = URL(string: urlPath ?? "")?.lastPathComponent {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: path.path) {
                return path
            }
        }
        guard let episodeUrl = urlPath, !episodeUrl.isEmpty else {
            return nil
        }
        return URL(string: episodeUrl)
    }
    
    func shouldDeleteFile(deleteCompletion: @escaping () -> ()) {
        if let fileName = URL(string: urlPath ?? "")?.lastPathComponent {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: path.path) {
                try? FileManager.default.removeItem(at: path)
                self.downloaded = false
                deleteCompletion()
            }
        }
    }
    
    /// Converts the HTML-formatted ``episodeDescription`` string to a standard Swift String
    var formattedDescription: String {
        episodeDescription?.attributedStringFromHTML?.string ?? ""
    }
}




