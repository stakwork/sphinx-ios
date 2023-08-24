//
//  DownloadService.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation

protocol DownloadServiceDelegate : class {
    func shouldReloadRowFor(download: Download)
    func shouldReloadRowFor(video:VideoDownload)
}

extension DownloadServiceDelegate{
    func shouldReloadRowFor(download: Download){}
    func shouldReloadRowFor(video:VideoDownload){}//default implementation does nothing
}

enum DownloadServiceDelegateKeys: String {
    case PodcastPlayerDelegate = "PodcastPlayerDelegate"
    case FeedItemDetailsDelegate = "FeedItemDetailsDelegate"
    case ItemDescriptionDelegate = "ItemDescriptionDelegate"
    case VideoFeedDelegate = "VideoFeedDelegate"
}

class DownloadService : NSObject {
    
    var delegates: [String: DownloadServiceDelegate] = [:]
    
    let downloadDispatchSemaphore = DispatchSemaphore(value: 1)
    
    class var sharedInstance : DownloadService {
        struct Static {
            static let instance = DownloadService()
        }
        return Static.instance
    }
    
    lazy var downloadsSession: URLSession = {
          let configuration = URLSessionConfiguration.background(withIdentifier: "com.gl.sphinx.bgSession")
          return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
  
    var activeDownloads: [String: Download] = [:]
    var activeVideoDownloads: [String: VideoDownload] = [:]
    private let downloadsQueue = DispatchQueue(label: "activeDownloads")


    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func setDelegate(
        delegate: DownloadServiceDelegate,
        forKey key: DownloadServiceDelegateKeys
    ) {
        self.delegates[key.rawValue] = delegate
    }
    
    func startDownload(video: Video) {
//        guard let url = video.getRemoteAudioUrl() else {
//            return
//        }
//
        if video.isDownloaded { return }
        
        //TODO: change to be the genuine raw mp4
        guard let url = URL(string: "https://s3.amazonaws.com/stakwork-uploads/uploads/customers/4291/media_to_local/cd7cae99-bb29-4f40-b050-4ade06b2fbf7/_-9RGlBIma8.mp4")//URL(string: "http://wilcal.test.website.bucket.s3-website-us-west-1.amazonaws.com/h.264/big_buck_bunny_h.264.mp4")
        else{
            return
        }

        let download = activeVideoDownloads[url.absoluteString] ?? VideoDownload(video: video)
        
//        if download.isDownloading {
//            pauseDownload(episode)
//            return
//        }
//
//        if let _ = download.resumeData {
//            resumeDownload(episode)
//            return
//        }
        
        download.progress = 0
        download.state = VideoDownload.State.downloading
        activeVideoDownloads[url.absoluteString] = download
        
        for d in self.delegates.values {
            d.shouldReloadRowFor(video: download)
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.downloadDispatchSemaphore.wait()
            
            download.task = self.downloadsSession.downloadTask(with: url)
            download.task?.resume()
        
            self.activeVideoDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
        }
    }

    func startDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else {
            return
        }
        
        if episode.isDownloaded { return }

        let download = activeDownloads[url.absoluteString] ?? Download(episode: episode)
        
        if download.isDownloading {
            pauseDownload(episode)
            return
        }
        
        if let _ = download.resumeData {
            resumeDownload(episode)
            return
        }
        
        download.progress = 0
        download.state = Download.State.downloading
        self.downloadsQueue.sync{
            activeDownloads[url.absoluteString] = download
        }
        
        
        for d in self.delegates.values {
            d.shouldReloadRowFor(download: download)
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.downloadDispatchSemaphore.wait()
            
            download.task = self.downloadsSession.downloadTask(with: url)
            download.task?.resume()
            self.downloadsQueue.sync{
                self.activeDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
            }
        }
    }
    
    func resumeDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else { return }

        guard let download = activeDownloads[url.absoluteString] else {
            return
        }
        
        download.state = Download.State.downloading

        DispatchQueue.global(qos: .utility).async {
            self.downloadDispatchSemaphore.wait()
            
            if let resumeData = download.resumeData {
                download.task = self.downloadsSession.downloadTask(withResumeData: resumeData)
            } else {
                download.task = self.downloadsSession.downloadTask(with: url)
            }
        
            download.task?.resume()
            
            self.downloadsQueue.sync {
                self.activeDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
            }
        }
        
        DispatchQueue.main.async {
            for d in self.delegates.values {
                d.shouldReloadRowFor(download: download)
            }
        }
    }

    func pauseDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else { return }

        guard let download = activeDownloads[url.absoluteString], download.isDownloading else {
            return
        }
                
        download.state = Download.State.paused

        download.task?.cancel(byProducingResumeData: { resumeDataOrNil in
            download.resumeData = resumeDataOrNil
        })
        
        downloadsQueue.sync {
            activeDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
        }
        
        downloadDispatchSemaphore.signal()
        
        DispatchQueue.main.async {
            for d in self.delegates.values {
                d.shouldReloadRowFor(download: download)
            }
        }
    }
    
    
}

extension DownloadService : URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        guard let url = downloadTask.originalRequest?.url ?? downloadTask.currentRequest?.url else {
            return
        }
        
        let urlString = url.absoluteString
        if let download = activeDownloads[urlString]{
            handlePodcastDownloadCompletion(download: download, urlString: urlString,location:location)
        }
        else if let download = activeVideoDownloads[urlString]{
            handleVideoDownloadCompletion(download: download, urlString: urlString, location: location)
        }
        
        
        
        downloadDispatchSemaphore.signal()
    }
    
    func handleVideoDownloadCompletion(download:VideoDownload?,urlString:String,location:URL){
        guard let fileName = download?.video.getLocalFileName() else {
            return
        }
        
        if let currentDownload = activeDownloads[urlString] {
            activeVideoDownloads[urlString] = nil
            
            if let originalUrl = currentDownload.originalUrl {
                activeVideoDownloads[originalUrl] = nil
            }
        }
      
        let destinationURL = localFilePath(for: fileName)

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)

        do {
            try fileManager.copyItem(at: location, to: destinationURL)
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
        
        if let download = download {
            DispatchQueue.main.async {
                for d in self.delegates.values {
                    d.shouldReloadRowFor(video: download)
                }
            }
        }
    }
    
    func handlePodcastDownloadCompletion(download:Download?,urlString:String,location:URL){
        guard let fileName = download?.episode.getLocalFileName() else {
            return
        }
        
        if let currentDownload = activeDownloads[urlString] {
            downloadsQueue.sync {
                self.activeDownloads[urlString] = nil
                
                if let originalUrl = currentDownload.originalUrl {
                    self.activeDownloads[originalUrl] = nil
                }
            }
        }
      
        let destinationURL = localFilePath(for: fileName)

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)

        do {
            try fileManager.copyItem(at: location, to: destinationURL)
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
        
        if let download = download {
            DispatchQueue.main.async {
                for d in self.delegates.values {
                    d.shouldReloadRowFor(download: download)
                }
            }
        }
    }
    
    func localFilePath(for fileName: String) -> URL {
        return documentsPath.appendingPathComponent(fileName)
    }
    
    func handleVideoDownloadUpdate(downloadTask: URLSessionDownloadTask,totalBytesWritten: Int64,totalBytesExpectedToWrite: Int64){
        guard let url = downloadTask.originalRequest?.url ?? downloadTask.currentRequest?.url, let download = activeVideoDownloads[url.absoluteString] else {
            return
        }
        
        let newProgress = Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100)
        print("Video Progress:\(newProgress)")
        
        if(newProgress >= 100){ //detect transition from downloading to download complete
            StorageManager.sharedManager.processGarbageCleanup()
        }
        
        if (download.progress == newProgress) {
            return
        }
        
        let shouldUpdateUI = abs(newProgress - download.progress) > 2
        
        if shouldUpdateUI {
            download.progress = newProgress
        }
        
        activeVideoDownloads[url.absoluteString] = download
        
        DispatchQueue.main.async {
            if shouldUpdateUI {
                for d in self.delegates.values {
                    d.shouldReloadRowFor(video: download)
                }
            }
        }
    }
    
    func handlePodcastDownloadUpdate(downloadTask: URLSessionDownloadTask,totalBytesWritten: Int64,totalBytesExpectedToWrite: Int64){
        guard let url = downloadTask.originalRequest?.url ?? downloadTask.currentRequest?.url, let download = activeDownloads[url.absoluteString] else {
            return
        }

        let newProgress = Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100)
        
        if (newProgress >= 100) { //detect transition from downloading to download complete
            StorageManager.sharedManager.processGarbageCleanup()
            
            download.episode.feed?.updateLastDownloadedEpisodeWith(
                id: download.episode.itemID
            )
        }
        
        if (download.progress == newProgress) {
            return
        }
        
        let shouldUpdateUI = abs(newProgress - download.progress) > 2
        
        if shouldUpdateUI {
            download.progress = newProgress
        }
        
        downloadsQueue.sync {
            activeDownloads[url.absoluteString] = download
        }
        
        DispatchQueue.main.async {
            if shouldUpdateUI {
                for d in self.delegates.values {
                    d.shouldReloadRowFor(download: download)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard let url = downloadTask.originalRequest?.url ?? downloadTask.currentRequest?.url else {
            return
        }
        
        if let _ = activeDownloads[url.absoluteString]{
            handlePodcastDownloadUpdate(downloadTask: downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
        
        if let _ = activeVideoDownloads[url.absoluteString]{
            handleVideoDownloadUpdate(downloadTask: downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
}
