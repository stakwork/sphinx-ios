//
//  StorageManager.swift
//  sphinx
//
//  Created by James Carucci on 5/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import SDWebImage

public enum StorageManagerMediaType{
    case audio
    case video
    case photo
}

struct StorageManagerItem{
    var type : StorageManagerMediaType
    var sizeMB : Double
    var label : String
    var date : Date
    var sourceFilePath:URL?
}

class StorageManager {
    
    private init() {}
    
    static let sharedManager = StorageManager()
    
    
    
    func getDownloadedPodcastsTotalSize()->Double{
        let dlPods = getDownloadedPodcastEpisodeList()
        let totalSize = dlPods.reduce(0) { (accumulator, item) in
            return accumulator + item.sizeMB
        }

        return totalSize
    }
    
    func cleanupGarbage(){
        if(checkForMemoryOverflow()){
            let downloadedPods = getDownloadedPodcastEpisodeList().sorted(by: {$0.date < $1.date})
            print(downloadedPods)
        }
    }
    
    func getAppDataSize() -> UInt64 {
        let fileManager = FileManager.default
        let appDataPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        
        var totalSize: UInt64 = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: appDataPath)
            
            for item in contents {
                let itemPath = (appDataPath as NSString).appendingPathComponent(item)
                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                print(attributes)
                if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                    totalSize += fileSize.uint64Value
                }
            }
        } catch {
            print("Error calculating app data size: \(error)")
        }
        
        return totalSize
    }
    
    func test(){
        let caches = SDImageCachesManager().caches
        print(caches)
    }
    
    func getWebImageCacheItems()->[StorageManagerItem]{
        var items = [StorageManagerItem]()
        
        let fileManager = FileManager.default
            guard let appDataPath = getSDWebImageCachePath(),
                  fileManager.fileExists(atPath: appDataPath) else {
                return []
            }

            var totalSize: UInt64 = 0

            do {
                let contents = try fileManager.contentsOfDirectory(atPath: appDataPath)

                for item in contents {
                    let itemPath = (appDataPath as NSString).appendingPathComponent(item)
                    let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                    print(attributes)
                    if let fileSize = attributes[FileAttributeKey.size] as? UInt64,
                       let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
                    let type = attributes[FileAttributeKey.type] as? String{
                        totalSize += fileSize
                        //StorageManagerItem(type: .photo, sizeMB: Double(fileSize)/1e6, label: "test", date: creationDate)
                    }
                }
            } catch {
                print("Error calculating app data size: \(error)")
            }
        
        
        return items
    }
    
    func getWebImageCacheSizeMB() -> UInt64 {
        let fileManager = FileManager.default
            guard let appDataPath = getSDWebImageCachePath(),
                  fileManager.fileExists(atPath: appDataPath) else {
                return 0
            }

            var totalSize: UInt64 = 0

            do {
                let contents = try fileManager.contentsOfDirectory(atPath: appDataPath)

                for item in contents {
                    let itemPath = (appDataPath as NSString).appendingPathComponent(item)
                    let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                    print(attributes)
                    if let fileSize = attributes[FileAttributeKey.size] as? UInt64 {
                        totalSize += fileSize
                    }
                }
            } catch {
                print("Error calculating app data size: \(error)")
            }

            return totalSize/1000000
    }
    
    func getSDWebImageCachePath() -> String? {
        let cacheDirectories = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let cacheDirectory = cacheDirectories.first {
            let sdWebImageCachePath = (cacheDirectory as NSString)//.appendingPathComponent("default/com.hackemist.SDWebImageCache.default")
            return sdWebImageCachePath as String
        }
        return nil
    }

    
    func checkForMemoryOverflow()->Bool{
        let podcastMemorySize = getDownloadedPodcastsTotalSize()
        let totalMemory = podcastMemorySize //TODO: add other media
        
        let maxMemoryGB = UserData.sharedInstance.getMaxMemory()
        let usedMemoryGB = Int(totalMemory/10)//totalMemory/1000
        return maxMemoryGB < usedMemoryGB
        //return Int(totalMemory/1000) > UserData.sharedInstance.getMaxMemory()
    }
    
    func getDownloadedPodcastEpisodeList()->[StorageManagerItem]{
        let pairs = extractFeedItemIdPairs()
        var storageItems = [StorageManagerItem]()
        for feedID in pairs.keys{
            //1. Recover the item as ContentFeedItem
            if let downloadedItemIDs = pairs[feedID]?.compactMap({
                let numericPart = $0.components(separatedBy: CharacterSet.decimalDigits.inverted)[0]
                let numericValue = String(numericPart)
                print(numericValue) // Output: 14685752600.0
                return numericValue
            }),
            let feed = ContentFeed.getFeedById(feedId: feedID)
               {
                let pf = PodcastFeed.convertFrom(contentFeed: feed)
                let downloadedItems = pf.episodesArray.filter({
                    downloadedItemIDs.contains($0.itemID)
                })
                //2. Extract the size value in MB
                for item in downloadedItems{
                    if let size = item.getFileSizeMB(){
                        let newItem = StorageManagerItem(type: .audio, sizeMB: size, label: "\(item.feed?.title ?? "Unknown Feed")- \(item.title ?? "Unknown Episode Title")",date: item.datePublished ?? (Date()),sourceFilePath: item.getAudioUrl())
                        storageItems.append(newItem)
                    }
                }
            }
        }
        return storageItems
    }
    
    func extractFeedItemIdPairs()->[String:[String]]{
        let files = scanDownloads()
        var results = [String: [String]]()
        for file in files{
            print(file.lastPathComponent)
            let split = file.lastPathComponent.split(separator: "_")
            if split.count > 1{
                var feedID = String(split[0])
                var itemID = String(split[1])
                if var existingFeedArray = results[feedID]{
                    existingFeedArray.append(itemID)
                    results[feedID] = existingFeedArray
                }
                else{
                    results[feedID] = [itemID]
                }
            }
        }
        return results
    }
    
    func scanDownloads()->[Foundation.URL] {
        if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print(path)
            do{
                let subDirectories = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                print(("Dox Dir:\(subDirectories)"))
                return subDirectories
            }
            catch{
                print("issue getting subdirectories")
            }
        }
        return []
    }
    
    func scanMessageMedia(){
        
    }
    
}
