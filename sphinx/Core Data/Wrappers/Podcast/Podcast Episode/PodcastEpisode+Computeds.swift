// PodcastEpisode+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation
import SwiftyJSON
import CoreData


extension PodcastEpisode {
    
    var isAvailable: Bool {
        get { ConnectivityHelper.isConnectedToInternet || isDownloaded }
    }
    
    var isDownloaded: Bool {
        get {
            if let fileName = getLocalFileName() {
                if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                    return FileManager.default.fileExists(atPath: path.path)
                }
            }
            return false
        }
    }
    
    func getRemoteAudioUrl() -> URL? {
        guard let episodeUrl = urlPath, !episodeUrl.isEmpty else {
            return nil
        }
        return URL(string: episodeUrl)
    }
    
    func getLocalFileName() -> String? {
        let itemID = itemID
        
        guard let feedId = feed?.feedID, !feedId.isEmpty, !itemID.isEmpty else {
            return nil
        }
        
        return "\(feedId)_\(itemID).mp3"
    }
    
    func getAudioUrl() -> URL? {
        if let fileName = getLocalFileName() {
            
            if let path = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(fileName) {
                
                if FileManager.default.fileExists(atPath: path.path) {
                    return path
                }
            }
        }
        return getRemoteAudioUrl()
    }
    
    func getFileSizeMB() -> Double?{
        if let path = getAudioUrl(){
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path.path)
                let fileSize = attributes[.size] as! UInt64
                let sizeInMB = Double(fileSize) / 1048576.0 // Convert bytes to megabytes
                print("File size: \(sizeInMB) MB")
                return sizeInMB
            } catch {
                // Handle the error here
                print("Error: \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    func shouldDeleteFile(deleteCompletion: @escaping () -> ()) {
        if let fileName = getLocalFileName() {
            
            if let path = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(fileName) {
                
                if FileManager.default.fileExists(atPath: path.path) {
                    try? FileManager.default.removeItem(at: path)
                    
                    self.feed?.updateLastDownloadedEpisodeWith(id: nil)
                    
                    deleteCompletion()
                }
            }
        }
    }
    
    /// Converts the HTML-formatted ``episodeDescription`` string to a standard Swift String
    var formattedDescription: String {
        episodeDescription?.attributedStringFromHTML?.string ?? ""
    }
}




