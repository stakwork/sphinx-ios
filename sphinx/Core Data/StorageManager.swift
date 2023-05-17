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
    
    static var allCases: [StorageManagerMediaType] {
            return [.audio, .video, .photo]
        }
}

public enum StorageMediaManagerSource{
    case episodes
    case chats
    
    static var allCases: [StorageMediaManagerSource]{
        return [.chats,.episodes]
    }
}

struct StorageManagerItem{
    var type : StorageManagerMediaType
    var sizeMB : Double
    var label : String
    var date : Date
    var sourceFilePath:URL?
    var cachedMedia:CachedMedia?
}

class StorageManager {
    
    private init() {}
    
    static let sharedManager = StorageManager()
    
    var downloadedPods = [StorageManagerItem]()//media intentionally stored by user when they dl podcasts
    var cachedMedia = [StorageManagerItem]() //media stored automatically from chat images by SDImage library
    //var downloadedVideos = [StorageManagerItem]()//this iteration does not yet support but will be for downloaded video content
    
    lazy var allItems : [StorageManagerItem] = {
        return downloadedPods + cachedMedia
    }()
    
    func getStorageItemSummaryByType()->[StorageManagerMediaType:Double]{
        var dict = [StorageManagerMediaType:Double]()
        let storedItemsByType = getStoredItemsByType()
        for type in StorageManagerMediaType.allCases{
            if let typeSpecificItems = storedItemsByType[type]{
                let total = getItemGroupTotalSize(items: typeSpecificItems)
                dict[type] = total
            }
        }
        return dict
    }
    
    func getStoredItemsByType()->[StorageManagerMediaType:[StorageManagerItem]]{
        var dict = [StorageManagerMediaType:[StorageManagerItem]]()
        for type in StorageManagerMediaType.allCases{
            dict[type] = allItems.filter({$0.type == type})
        }
        return dict
    }
    
    func getStoredItemsBySource()->[StorageMediaManagerSource:[StorageManagerItem]]{
        var dict = [StorageMediaManagerSource:[StorageManagerItem]]()
        dict[.episodes] = downloadedPods
        dict[.chats] = cachedMedia
        return dict
    }
    
    func refreshAllStoredData(completion:@escaping ()->()){
        downloadedPods = getDownloadedPodcastEpisodeList()
        getImageCacheItems(completion: { results in
            self.cachedMedia = results
            completion()
        })
    }
    
    func getDownloadedPodcastsTotalSizeMB()->Double{
        return getItemGroupTotalSize(items: downloadedPods)
    }
    
    func getCachedMediaTotalSizeMB()->Double{
        return getItemGroupTotalSize(items: cachedMedia)
    }
    
    func getItemGroupTotalSize(items:[StorageManagerItem])->Double{
        let totalSize = items.reduce(0) { (accumulator, item) in
            return accumulator + item.sizeMB
        }

        return totalSize
    }
    
    func cleanupGarbage(){
        if(checkForMemoryOverflow()){
            //deleteOldestPod()
        }
    }
    
    func getImageCacheItems(completion: @escaping ([StorageManagerItem])->()) {
        let imageCache = SDImageCache.shared
        let diskCachePath = imageCache.diskCachePath
        let fileManager = FileManager.default
        
        guard let cacheFiles = fileManager.enumerator(atPath: diskCachePath) else {
            print("Unable to retrieve cache files")
            completion([])
            return
        }
        var items = [StorageManagerItem]()
        for file in cacheFiles {
            guard let filePath = file as? String else {
                continue
            }
            
            let imagePath = (diskCachePath as NSString).appendingPathComponent(filePath)
            guard let image = UIImage(contentsOfFile: imagePath) else {
                continue
            }
            
            var size : UInt64? = nil
            do{
                let imagePath = (diskCachePath as NSString).appendingPathComponent(filePath)
                let attributes = try fileManager.attributesOfItem(atPath: imagePath)
                print(attributes)
                if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                    size = fileSize.uint64Value
                }
            }
            catch{
                print("error retrieving size of image")
            }
            
            if let cm = (CachedMedia.getCachedMediaByFilePath(filePath: imagePath)){
                cm.image = image
                let newItem = StorageManagerItem(type: .photo, sizeMB: Double(size ?? 0)/1e6, label: "", date:cm.creationDate ?? Date()  ,cachedMedia: cm)
                items.append(newItem)
            }
            
            // Display or process the image as needed
            print("Image path: \(imagePath)")
            // Example: UIImageView(image: image)
        }
        completion(items)
    }
    
    func deleteCacheItems(cms:[CachedMedia]){
        for cm in cms{
            cm.removeCachedMediaAndDeleteObject()
        }
    }

    //returns a boolean that determines whether memory needs to be culled
    func checkForMemoryOverflow()->Bool{
        let podcastMemorySize = getDownloadedPodcastsTotalSizeMB()
        let totalMemory = podcastMemorySize //TODO: add other media
        
        let maxMemoryGB = UserData.sharedInstance.getMaxMemoryGB()
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
    
}
