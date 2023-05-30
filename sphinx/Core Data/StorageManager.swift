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
        return [
            .photo,
            .video,
            .audio
        ]
    }
}

public enum StorageManagerMediaSource{
    case podcasts
    case chats
    
    static var allCases: [StorageManagerMediaSource]{
        return [
            .chats,
            .podcasts
        ]
    }
}

struct StorageManagerItem{
    var type : StorageManagerMediaType
    var sizeMB : Double
    var label : String
    var date : Date
    var sourceFilePath:String?
    var cachedMedia:CachedMedia?
    var uid:String?=nil
    
    func isCachedMedia()->Bool{
        return cachedMedia != nil
    }
    
    func isPodcast()->Bool{
        return uid != nil//for now this is how we can do it
    }
    
}

class StorageManager {
    
    private init() {}
    
    static let sharedManager = StorageManager()
    
    var downloadedPods = [StorageManagerItem]()//media intentionally stored by user when they dl podcasts
    var cachedMedia = [StorageManagerItem]() //media stored automatically from chat images by SDImage library
    //var downloadedVideos = [StorageManagerItem]()//this iteration does not yet support but will be for downloaded video content
    
    var allItems : [StorageManagerItem]  {
        return downloadedPods + cachedMedia
    }
    
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
    
    func getStorageItemSummaryBySource()->[StorageManagerMediaSource:Double]{
        var dict = [StorageManagerMediaSource:Double]()
        let storedItemsByType = getStoredItemsBySource()
        for source in StorageManagerMediaSource.allCases{
            if let typeSpecificItems = storedItemsByType[source]{
                let total = getItemGroupTotalSize(items: typeSpecificItems)
                dict[source] = total
            }
        }
        return dict
    }
    
    func getStoredItemsBySource()->[StorageManagerMediaSource:[StorageManagerItem]]{
        var dict = [StorageManagerMediaSource:[StorageManagerItem]]()
        dict[.podcasts] = downloadedPods
        dict[.chats] = cachedMedia
        return dict
    }
    
    func getItemDetailsByChat()->[Chat:[StorageManagerItem]]{
        let bySource = getStoredItemsBySource()
        var chatsToItemDict = [Chat:[StorageManagerItem]]()
        if let chatsOnly = bySource[.chats]{
            for item in chatsOnly{
                print(item.cachedMedia)
                if let cm = item.cachedMedia,
                   let itemsChat = cm.chat{
                    if chatsToItemDict[itemsChat] != nil{
                        chatsToItemDict[itemsChat]!.append(item)
                    }
                    else{
                        chatsToItemDict[itemsChat] = [item]
                    }
                }
            }
        }
        return chatsToItemDict
    }
    
    func getItemDetailsByPodcastFeed()->[PodcastFeed:[StorageManagerItem]]{
        let bySource = getStoredItemsBySource()
        var podcastsToItemDict = [PodcastFeed:[StorageManagerItem]]()
        if let podcastsOnly = bySource[.podcasts]{
            for item in podcastsOnly{
                if let itemID = item.uid,
                   let episode = FeedsManager.sharedInstance.fetchPodcastEpisode(itemID: itemID),
                   let cf = episode.contentFeed{
                    var feed = PodcastFeed.convertFrom(contentFeed: cf)
                    feed = podcastsToItemDict.keys.filter({$0.feedID == feed.feedID}).first ?? feed
                    if podcastsToItemDict[feed] != nil{
                        podcastsToItemDict[feed]!.append(item)
                    }
                    else{
                        podcastsToItemDict[feed] = [item]
                    }
                }
            }
        }
        return podcastsToItemDict
    }
    
    func refreshAllStoredData(completion:@escaping ()->()){
        
        downloadedPods = getDownloadedPodcastEpisodeList()
        getImageCacheItems(completion: { results in
            self.cachedMedia = results
            self.getSphinxCacheVideos(completion: {videoResults in
                self.cachedMedia += videoResults
                completion()
            })
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
    
    func cleanupGarbage(completion:@escaping ()->()){
        var wdt_flag = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 300.0, execute: {
            wdt_flag = false
        })
        let choppingBlockSnapshot = allItems.sorted(by: {$0.date < $1.date})//static snapshot that never changes
        var changingChoppingBlock = choppingBlockSnapshot//changes so we can compare against limit
        var i = 0
        var semaphore = false
        while(checkForMemoryOverflow(items: changingChoppingBlock) && wdt_flag){
            if(semaphore == false){//only allow deletion if semaphore isn't active
                semaphore = true
                deleteItem(item: choppingBlockSnapshot[i], completion: {
                    semaphore = false//allow next deletion
                    changingChoppingBlock[i].sizeMB = 0.0
                    i += 1
                })
            }
            wdt_flag = (i >= choppingBlockSnapshot.count - 1) ? false : wdt_flag
        }
        wdt_flag = false
        completion()
    }
    
    func deleteItem(item:StorageManagerItem,completion: @escaping ()->()){
        if(item.isCachedMedia()){
            deleteCacheItems(cms: [item.cachedMedia!], completion: {
                completion()
            })
        }
        else if(item.isPodcast()),
               let sourcePath = item.sourceFilePath{
            deletePodsWithID(
                fileName: sourcePath,
                successCompletion: {
                    completion()
                },
                failureCompletion: {
                    completion()
                }
            )
        }
        else{
            completion()
        }
    }
    
    func getSphinxCacheVideos(completion: @escaping ([StorageManagerItem]) -> ()) {
        let blah = CachedMedia.getAll()
        let videoCMs = blah.filter({ cm in cm.fileExtension != "png" })
        let fileManager = FileManager.default
        
        var items = [StorageManagerItem]()
        let sc = SphinxCache()
        for cm in videoCMs {
            var size: UInt64? = nil
            do {
                if let key = cm.key,
                   let fileData = sc.value(forKey: key) {
                    size = UInt64(fileData.count)
                    
                    let newItem = StorageManagerItem(type: .video, sizeMB: Double(size ?? 0) / 1e6, label: "", date: cm.creationDate ?? Date(), cachedMedia: cm)
                    items.append(newItem)
                }
            } catch {
                print("Error retrieving size of the file")
            }
        }
        
        print(items)
        populateVideoImages(smis: items)
        completion(items)
    }
    
    func populateVideoImages(smis:[StorageManagerItem]){
        let sc = SphinxCache()
        for smi in smis{
            if let cm = smi.cachedMedia,
               let key = cm.key,
               let data = sc.value(forKey: key){
                MediaLoader.getThumbnailImageFromVideoData(data: data, videoUrl: key, completion: { image in
                    if let newImage = image{
                        smi.cachedMedia?.image = newImage
                    }
                    else{
                        smi.cachedMedia?.image = #imageLiteral(resourceName: "videoPlaceholder")
                    }
                })
            }
        }
    }

    
    func getImageCacheItems(completion: @escaping ([StorageManagerItem])->()) {
        cachedMedia = []
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
            
            var size: UInt64? = nil
            var isVideo: Bool = false
            do {
                let imagePath = (diskCachePath as NSString).appendingPathComponent(filePath)
                let attributes = try fileManager.attributesOfItem(atPath: imagePath)
                print(attributes)
                if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                    size = fileSize.uint64Value
                }
                
                let fileExtension = URL(fileURLWithPath: imagePath).pathExtension.lowercased()
                let photoExtensions = ["jpg", "jpeg", "png","svg"] // Add more video extensions if needed
                
                isVideo = (photoExtensions.contains(fileExtension) == false) ? true : false
                
                if let cm = (CachedMedia.getCachedMediaByFilePath(filePath: imagePath, isVideo: isVideo)){
                    cm.image = image
                    let newItem = StorageManagerItem(type: .photo, sizeMB: Double(size ?? 0)/1e6, label: "", date:cm.creationDate ?? Date()  ,cachedMedia: cm)
                    items.append(newItem)
                }
                
            } catch {
                print("error retrieving size of image")
            }
            
            
            // Display or process the image as needed
            print("Image path: \(imagePath)")
            // Example: UIImageView(image: image)
        }
        completion(items)
    }
    
    
    func deleteCacheItems(cms:[CachedMedia],completion: @escaping ()->()){
        var cmCounter = cms.count
        cmCounter == 0 ? (completion()) : ()
        for cm in cms{
            if cm.fileExtension == "png"{
                cm.removePhotoObject(completion: {
                    cmCounter -= 1
                    cmCounter > 0 ? () : (completion())
                })
            }
            else if cm.fileExtension == "mp4"{
                cm.removeVideoObject(completion: {
                    cmCounter -= 1
                    cmCounter > 0 ? () : (completion())
                })
            }
        }
    }
    
    func deleteAllVideos(completion:@escaping ()->()){
        let allVids = allItems.filter({$0.type == .video}).compactMap({$0.cachedMedia})
        deleteCacheItems(cms: allVids, completion: {
            completion()
        })
    }
    
    func deleteAllImages(completion:@escaping ()->()){
        let allImages = allItems.filter({$0.type == .photo}).compactMap({$0.cachedMedia})
        deleteCacheItems(cms: allImages,completion: {
            completion()
        })
    }
    
    func deleteAllAudioFiles(completion: @escaping ()->()){
        var podsCounter = downloadedPods.count
        podsCounter == 0 ? (completion()) : ()
        for pod in downloadedPods{
            if let sourcePath = pod.sourceFilePath{
                deletePodsWithID(
                    fileName: sourcePath,
                    successCompletion: {
                    print("deleted pod with id:\(pod.uid)")
                        podsCounter-=1
                        podsCounter > 0 ? () : completion()
                    },
                    failureCompletion: {
                        print("failed to delete pod with id:\(pod.uid)")
                        podsCounter-=1
                        podsCounter > 0 ? () : completion()
                    })
            }
        }
    }
    
    func deletePodsWithID(fileName:String,successCompletion: @escaping ()->(),failureCompletion: @escaping ()->()){
        if let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName) {
            
            if FileManager.default.fileExists(atPath: path.path) {
                try? FileManager.default.removeItem(at: path)
                successCompletion()
            }
            else{
                failureCompletion()
            }
        }
        else{
            failureCompletion()
        }
    }

    //returns a boolean that determines whether memory needs to be culled
    func checkForMemoryOverflow(items:[StorageManagerItem])->Bool{
        let totalMemory = getItemGroupTotalSize(items: items) //TODO: add other media
        
        let maxMemoryGB = UserData.sharedInstance.getMaxMemoryGB() * 1000//convert to MB
        let usedMemoryGB = Int(totalMemory)//MB
        return maxMemoryGB < usedMemoryGB
    }
    
    //returns an array of structs describing each downloaded podcast episode
    func getDownloadedPodcastEpisodeList()->[StorageManagerItem]{
        downloadedPods = []
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
                        let newItem = StorageManagerItem(type: .audio, sizeMB: size, label: "\(item.feed?.title ?? "Unknown Feed")- \(item.title ?? "Unknown Episode Title")",date: item.datePublished ?? (Date()),sourceFilePath: item.getLocalFileName(),uid: item.itemID)
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
