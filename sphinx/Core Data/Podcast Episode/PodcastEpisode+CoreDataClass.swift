// PodcastEpisode+CoreDataClass.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation
import CoreData


@objc(PodcastEpisode)
public class PodcastEpisode: NSManagedObject, Decodable {
    
    // MARK: - Decodable
    public required convenience init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.managedObjectContext]
                as? NSManagedObjectContext
        else {
            preconditionFailure("No managedObjectContext found in decoder userInfo")
        }
        
        self.init(context: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        datePublished = Date(
            timeIntervalSince1970: try container.decode(Double.self, forKey: .datePublished)
        )
        episodeDescription = try container.decode(String.self, forKey: .episodeDescription)
        urlPath = try container.decode(String.self, forKey: .urlPath)
        imageURLPath = try container.decode(String.self, forKey: .imageURLPath)
        linkURLPath = try container.decode(String.self, forKey: .linkURLPath)
    }
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
