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
    case file
    
    static var allCases: [StorageManagerMediaType] {
        return [
            .photo,
            .video,
            .audio,
            .file
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

class StorageManagerItem{
    var type : StorageManagerMediaType
    var source: StorageManagerMediaSource
    var sizeMB : Double
    var label : String
    var date : Date
    var sourceFilePath: String?
    var cachedMedia: CachedMedia?
    var uid:String? = nil
    
    init(
        source: StorageManagerMediaSource,
        type: StorageManagerMediaType,
        sizeMB: Double,
        label: String,
        date: Date,
        sourceFilePath: String?=nil,
        cachedMedia: CachedMedia?=nil,
        uid: String?=nil
    ) {
        self.type = type
        self.sizeMB = sizeMB
        self.label = label
        self.date = date
        self.sourceFilePath = sourceFilePath
        self.cachedMedia = cachedMedia
        self.uid = uid
        self.source = source
    }
    
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
    
    var garbageCleanIsInProgress : Bool = false
    var downloadedPods = [StorageManagerItem]()//media intentionally stored by user when they dl podcasts
    var cachedMedia = [StorageManagerItem]() //media stored automatically from chat images by SDImage library
    //var downloadedVideos = [StorageManagerItem]()//this iteration does not yet support but will be for downloaded video content
    
    var allItems : [StorageManagerItem]  {
        return downloadedPods + cachedMedia
    }
    
    func getStorageManagerTypeFromExtension(cm:CachedMedia)->StorageManagerMediaType{
        var type : StorageManagerMediaType = .file
        if(cm.fileExtension == "png"){
            type = .photo
        }
        else if(cm.fileExtension == "mp4"){
            type = .video
        }
        else if(cm.fileExtension == "mp3"){
            type = .audio
        }
        
        return type
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
    
    func getTop3ChatImages()->[String]{
        let chats = getItemDetailsByChat().keys.map({$0})
        let urls = chats.compactMap({$0.getPhotoUrl()})
        var results : [String] = []
        for i in 0..<3{
            var newURL =  ""
            if(urls.count - 1 > i){
                newURL = urls[i]
            }
            results.append(newURL)
        }
        return results
    }
    
    func getItemDetailsByChat()->[Chat:[StorageManagerItem]]{
        let bySource = getStoredItemsBySource()
        var chatsToItemDict = [Chat:[StorageManagerItem]]()
        if let chatsOnly = bySource[.chats]{
            for item in chatsOnly{
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
                self.populateVideoImages()
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
    
    func processGarbageCleanup(){
        if(garbageCleanIsInProgress == false){
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                self.refreshAllStoredData {
                    self.cleanupGarbage(completion: {
                        self.refreshAllStoredData {}
                    })
                }
            })
        }
    }
    
    func cleanupGarbage(completion:@escaping ()->()){
        garbageCleanIsInProgress = true
        var wdt_flag = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 300.0, execute: {
            wdt_flag = false
        })
        let choppingBlockSnapshot = allItems.sorted(by: {$0.date < $1.date})//static snapshot that never changes
        let changingChoppingBlock = choppingBlockSnapshot//changes so we can compare against limit
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
        
        //now cleanup old chat media
        self.deleteAllOldChatMedia(completion: {
            wdt_flag = false
            self.garbageCleanIsInProgress = false
            completion()
        })
        
    }
    
    func deleteItem(item:StorageManagerItem,completion: @escaping ()->()){
        if(item.isCachedMedia()){
            deleteCacheItems(cms: [item.cachedMedia!], completion: {
                completion()
            })
        }
        else if(item.isPodcast()),
               let sourcePath = item.sourceFilePath{
            deletePodEpisodeWithFileName(
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
        
        var items = [StorageManagerItem]()
        let sc = SphinxCache()
        for cm in videoCMs {
            var size: UInt64? = nil
            
            if let key = cm.key,
               let fileData = sc.value(forKey: key) {
                size = UInt64(fileData.count)
                
                let type = getStorageManagerTypeFromExtension(cm:cm)
                
                let newItem = StorageManagerItem(source: .chats, type: type, sizeMB: Double(size ?? 0) / 1e6, label: "", date: cm.creationDate ?? Date(), cachedMedia: cm)
                items.append(newItem)
            }
        }
        
        print(items)
        completion(items)
    }
    
    func populateVideoImages(){
        let smis = allItems.filter({$0.type != .photo && $0.type != .audio})
        let sc = SphinxCache()
        for i in 0..<smis.count{
            let smi = smis[i]
            if let cm = smi.cachedMedia,
               let key = cm.key,
               let data = sc.value(forKey: key) {
                if let image = MediaLoader.getImageFromCachedUrl(url: key) {
                    smi.cachedMedia?.image = image
                } else {
                    MediaLoader.getThumbnailImageFromVideoData(data: data, videoUrl: key, completion: { image in
                        if let newImage = image {
                            smi.cachedMedia?.image = newImage
                        } else {
                            var defaultImage = #imageLiteral(resourceName: "videoPlaceholder")
                            if let cm = smi.cachedMedia
                            {
                                let ext = (self.getStorageManagerTypeFromExtension(cm: cm))
                                defaultImage = (ext == .file) ?  #imageLiteral(resourceName: "fileOptionIcon") : defaultImage
                                defaultImage = (ext == .audio) ?  #imageLiteral(resourceName: "playPodcastIcon") : defaultImage
                            }
                        }
                    })
                }
            }
        }
    }
    
    func performPopulateVideoJob(
        data: Data,
        key: String,
        smi: StorageManagerItem,
        completion: @escaping () -> ()
    ){
        if let image = MediaLoader.getImageFromCachedUrl(url: key) {
            smi.cachedMedia?.image = image
            completion()
        } else {
            completion()
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
                    let newItem = StorageManagerItem(source: .chats, type: .photo, sizeMB: Double(size ?? 0)/1e6, label: "", date:cm.creationDate ?? Date()  ,cachedMedia: cm)
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
            else{
                cm.removeSphinxCacheObject(completion: {
                    cmCounter -= 1
                    cmCounter > 0 ? () : (completion())
                })
            }
        }
    }
    
    func deleteAllOtherFiles(completion:@escaping ()->()){
        let allVids = allItems.filter({$0.type == .file}).compactMap({$0.cachedMedia})
        deleteCacheItems(cms: allVids, completion: {
            completion()
        })
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
        deleteAllPodcasts(completion: {
            self.deleteAllAudioMessages(completion: {
                completion()
            })
        })
    }
    
    func deleteAllAudioMessages(completion: @escaping ()->()){
        let allFiles = allItems.filter({$0.type == .audio}).compactMap({$0.cachedMedia})
        deleteCacheItems(cms: allFiles,completion: {
            completion()
        })
    }
    
    func deleteAllPodcasts(completion:@escaping ()->()){
        var podsCounter = downloadedPods.count
        podsCounter == 0 ? (completion()) : ()
        for pod in downloadedPods {
            if let sourcePath = pod.sourceFilePath{
                deletePodEpisodeWithFileName(
                    fileName: sourcePath,
                    successCompletion: {
                        podsCounter-=1
                        podsCounter > 0 ? () : completion()
                    },
                    failureCompletion: {
                        podsCounter-=1
                        podsCounter > 0 ? () : completion()
                    })
            }
        }
    }
    
    func deletePodEpisodeWithFileName(
        fileName: String,
        successCompletion: @escaping ()->(),
        failureCompletion: @escaping ()->()
    ){
        if let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName) {
            
            if FileManager.default.fileExists(atPath: path.path) {
                try? FileManager.default.removeItem(at: path)
                updateLastDownloadedEpisodeFor(fileName: fileName)
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
    
    func updateLastDownloadedEpisodeFor(fileName: String) {
        if let feedId = getFeedIdFrom(fileName: fileName) {
            if let feed = ContentFeed.getFeedById(feedId: feedId) {
                feed.lastDownloadedEpisodeId = nil
            }
        }
    }
    
    func getFeedIdFrom(fileName: String) -> String? {
        if let feedId = fileName.split(separator: "_").first {
            return String(feedId)
        }
        return nil
    }
    
    func deleteAllOldChatMedia(completion: @escaping ()->()){
        let now = Date()
        if let cutoffDatetime = Calendar.current.date(byAdding: .day, value: -30, to: now){
            let oldMediaOnChoppingBlock = allItems.filter({$0.source == .chats && $0.date < cutoffDatetime}).compactMap({$0.cachedMedia})
            deleteCacheItems(cms: oldMediaOnChoppingBlock, completion: {
                print("done")
            })
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
                        let newItem = StorageManagerItem(source: .podcasts, type: .audio, sizeMB: size, label: "\(item.feed?.title ?? "Unknown Feed")- \(item.title ?? "Unknown Episode Title")",date: item.datePublished ?? (Date()),sourceFilePath: item.getLocalFileName(),uid: item.itemID)
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
            if let split = getFeedItemPairForString(string: file.lastPathComponent),
               split.count > 1{
                let feedID = String(split[0])
                let itemID = String(split[1])
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
    
    func getFeedItemPairForString(string:String)->[String]?{
        let split = string.split(separator: "_")
        if split.count > 1{
            let feedID = String(split[0])
            let itemID = String(split[1])
            
            return [feedID,itemID]
        }
        
        return nil
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
