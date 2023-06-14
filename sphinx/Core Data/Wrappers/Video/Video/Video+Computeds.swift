// Video+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation


extension Video {
    
    static let publishDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        
        return formatter
    }()
    
    var dateString : String?{
        let date = self.datePublished
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let valid_date = date{
            let dateString = formatter.string(from: valid_date)
            return dateString
        }
        return nil
    }
    
    var isDownloaded: Bool {
        get {
            if let fileName = getLocalFileName() {
                if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                    let exists = FileManager.default.fileExists(atPath: path.path)
                    return exists
                }
            }
            return false
        }
    }
    
    func getLocalFileName() -> String? {
        let itemID = id
        
        guard let feedId = videoFeed?.feedID, !feedId.isEmpty, !itemID.isEmpty else {
            return nil
        }
        
        return "\(feedId)_\(itemID).mp4"
    }
    
    
    func getVideoUrl() -> URL? {
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
        return self.itemURL
    }
}
