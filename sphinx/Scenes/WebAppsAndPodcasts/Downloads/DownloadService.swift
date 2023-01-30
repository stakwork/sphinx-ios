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
    func shouldUpdateProgressFor(download: Download)
}

class DownloadService : NSObject {
    
    var delegate: DownloadServiceDelegate? = nil
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
    
    func setDelegate(delegate: DownloadServiceDelegate) {
        self.delegate = delegate
    }

    func startDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else {
            return
        }
        
        if episode.isDownloaded { return }

        let download = activeDownloads[url.absoluteString] ?? Download(episode: episode)
        
        if download.isDownloading { return }
        
        download.progress = 0
        download.isDownloading = true
        activeDownloads[url.absoluteString] = download
        
        delegate?.shouldReloadRowFor(download: download)
        
        DispatchQueue.global().async {
            self.downloadDispatchSemaphore.wait()
            
            download.task = self.downloadsSession.downloadTask(with: url)
            download.task?.resume()
            self.activeDownloads[url.absoluteString] = download
        }
    }
    
    func resumeDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else { return }

        guard let download = activeDownloads[url.absoluteString] else {
            return
        }

        DispatchQueue.global().async {
            self.downloadDispatchSemaphore.wait()
            
            if let resumeData = download.resumeData {
                download.task = self.downloadsSession.downloadTask(withResumeData: resumeData)
            } else {
                download.task = self.downloadsSession.downloadTask(with: url)
            }

            download.task?.resume()
            download.isDownloading = true
            
            self.activeDownloads[url.absoluteString] = download
        }
    }
    
    func cancelDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else { return }

        guard let download = activeDownloads[url.absoluteString] else {
            return
        }
        download.task?.cancel()

        activeDownloads[url.absoluteString] = nil
    }

    func pauseDownload(_ episode: PodcastEpisode) {
        guard let url = episode.getRemoteAudioUrl() else { return }

        guard let download = activeDownloads[url.absoluteString], download.isDownloading else {
            return
        }

        download.task?.cancel(byProducingResumeData: { data in
            download.resumeData = data
        })

        download.isDownloading = false
        activeDownloads[url.absoluteString] = download
        
        downloadDispatchSemaphore.signal()
    }
}

extension DownloadService : URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        guard let url = downloadTask.originalRequest?.url else {
            return
        }
        
        let urlString = url.absoluteString
        let download = activeDownloads[urlString]
        
        guard let fileName = download?.episode.getLocalFileName() else {
            return
        }
        
        activeDownloads[urlString] = nil
      
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
                self.delegate?.shouldReloadRowFor(download: download)
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
        
        guard let url = downloadTask.originalRequest?.url, let download = activeDownloads[url.absoluteString] else {
            return
        }

        let newProgress = Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100)
        
        if (download.progress == newProgress) {
            return
        }
        
        download.progress = newProgress
        activeDownloads[url.absoluteString] = download
        
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        
        print("PROGRESS: \(download.progress) FROM \(totalSize)")
        
        DispatchQueue.main.async {
            self.delegate?.shouldUpdateProgressFor(download: download)
        }
    }
}
