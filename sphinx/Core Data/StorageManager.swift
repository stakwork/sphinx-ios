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
            //deleteOldestPod()
        }
    }
    
    func deleteOldestPod(){
        if let oldestPod = getDownloadedPodcastEpisodeList().sorted(by: {$0.date < $1.date}).first
        {
            //WIP
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
    
    
    func getImageCacheSize()->UInt64 {
        let fileManager = FileManager.default
        let imageCache = SDImageCache.shared
        let diskCachePath = imageCache.diskCachePath
        var totalSize: UInt64 = 0
        guard let cacheFiles = FileManager.default.enumerator(atPath: diskCachePath) else {
            print("Unable to retrieve cache files")
            return 0
        }
        
        for file in cacheFiles {
            guard let filePath = file as? String else {
                continue
            }
            do{
                let imagePath = (diskCachePath as NSString).appendingPathComponent(filePath)
                let attributes = try fileManager.attributesOfItem(atPath: imagePath)
                print(attributes)
                if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                    totalSize += fileSize.uint64Value
                }
            }
            catch{
                print("error retrieving size of image")
            }
        }
        
        return totalSize
    }
    
    func getImageCacheItems()->[CachedMedia] {
        let imageCache = SDImageCache.shared
        let diskCachePath = imageCache.diskCachePath
        
        guard let cacheFiles = FileManager.default.enumerator(atPath: diskCachePath) else {
            print("Unable to retrieve cache files")
            return []
        }
        var images = [CachedMedia]()
        for file in cacheFiles {
            guard let filePath = file as? String else {
                continue
            }
            
            let imagePath = (diskCachePath as NSString).appendingPathComponent(filePath)
            guard let image = UIImage(contentsOfFile: imagePath) else {
                continue
            }
            if imagePath.contains("78ca1ccafa8b9d3788f5bac3ad") == true,
               let cm = (CachedMedia.getCachedMediaByFilePath(filePath: imagePath)){
                images.append(cm)
            }
            else if(imagePath.contains("78ca1ccafa8b9d3788f5bac3ad")){
                print(imagePath)
            }
            
            // Display or process the image as needed
            print("Image path: \(imagePath)")
            // Example: UIImageView(image: image)
        }
        return images
    }
    
    func deleteCacheItems(cms:[CachedMedia]){
        for cm in cms{
            cm.removeCachedMediaAndDeleteObject()
        }
    }

    //returns a boolean that determines whether memory needs to be culled
    func checkForMemoryOverflow()->Bool{
        let podcastMemorySize = getDownloadedPodcastsTotalSize()
        let totalMemory = podcastMemorySize //TODO: add other media
        
        let maxMemoryGB = UserData.sharedInstance.getMaxMemory()
        let usedMemoryGB = Int(totalMemory/10)//totalMemory/1000
        return maxMemoryGB < usedMemoryGB
        //return Int(totalMemory/1000) > UserData.sharedInstance.getMaxMemory()
    }
    
    //returns an array of structs describing each downloaded podcast episode
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
    
    //returns a dictionary of feedIDs as keys and downloaded itemID arrays as the values
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
