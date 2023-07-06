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
}

enum DownloadServiceDelegateKeys: String {
    case PodcastPlayerDelegate = "PodcastPlayerDelegate"
    case FeedItemDetailsDelegate = "FeedItemDetailsDelegate"
    case ItemDescriptionDelegate = "ItemDescriptionDelegate"
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

    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func setDelegate(
        delegate: DownloadServiceDelegate,
        forKey key: DownloadServiceDelegateKeys
    ) {
        self.delegates[key.rawValue] = delegate
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
        activeDownloads[url.absoluteString] = download
        
        for d in self.delegates.values {
            d.shouldReloadRowFor(download: download)
        }
        
        DispatchQueue.global(qos: .utility).async {
            self.downloadDispatchSemaphore.wait()
            
            download.task = self.downloadsSession.downloadTask(with: url)
            download.task?.resume()
        
            self.activeDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
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
            
            self.activeDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
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

        activeDownloads[download.task?.currentRequest?.url?.absoluteString ?? url.absoluteString] = download
        
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
        let download = activeDownloads[urlString]
        
        guard let fileName = download?.episode.getLocalFileName() else {
            return
        }
        
        if let currentDownload = activeDownloads[urlString] {
            activeDownloads[urlString] = nil
            
            if let originalUrl = currentDownload.originalUrl {
                activeDownloads[originalUrl] = nil
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
        
        downloadDispatchSemaphore.signal()
    }
    
    func localFilePath(for fileName: String) -> URL {
        return documentsPath.appendingPathComponent(fileName)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard let url = downloadTask.originalRequest?.url ?? downloadTask.currentRequest?.url, let download = activeDownloads[url.absoluteString] else {
            return
        }

        let newProgress = Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100)
        
        if (newProgress >= 100) { //detect transition from downloading to download complete
            FeedsManager.sharedInstance.fetchContentFeedItemFromPodcastEpisode(episode: download.episode, completion: { matchedItem in
                if let matchedItem = matchedItem{
                    matchedItem.downloaded_at = Date()
                    CoreDataManager.sharedManager.saveContext()
                }
            })
            StorageManager.sharedManager.processGarbageCleanup()
        }
        
        if (download.progress == newProgress) {
            return
        }
        
        let shouldUpdateUI = abs(newProgress - download.progress) > 2
        
        if shouldUpdateUI {
            download.progress = newProgress
        }
        
        activeDownloads[url.absoluteString] = download
        
        DispatchQueue.main.async {
            if shouldUpdateUI {
                for d in self.delegates.values {
                    d.shouldReloadRowFor(download: download)
                }
            }
        }
    }
}
