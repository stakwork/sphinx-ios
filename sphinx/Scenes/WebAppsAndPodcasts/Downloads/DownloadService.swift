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
  
    var activeDownloads: [String: Download] = [ : ]
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    func setDelegate(delegate: DownloadServiceDelegate) {
        self.delegate = delegate
    }

    func cancelDownload(_ episode: PodcastEpisode) {
        guard let urlString = episode.urlPath else { return }

        guard let download = activeDownloads[urlString] else {
            return
        }
        download.task?.cancel()

        activeDownloads[urlString] = nil
    }

    func pauseDownload(_ episode: PodcastEpisode) {
        guard let urlString = episode.urlPath else { return }

        guard let download = activeDownloads[urlString], download.isDownloading else {
            return
        }

        download.task?.cancel(byProducingResumeData: { data in
            download.resumeData = data
        })

        download.isDownloading = false
    }

    func resumeDownload(_ episode: PodcastEpisode) {
        guard let urlString = episode.urlPath, let url = URL(string: urlString) else { return }

        guard let download = activeDownloads[urlString] else {
            return
        }

        if let resumeData = download.resumeData {
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.task = downloadsSession.downloadTask(with: url)
        }

        download.task?.resume()
        download.isDownloading = true
    }

    func startDownload(_ episode: PodcastEpisode) {
        guard let urlString = episode.urlPath, let url = URL(string: urlString) else { return }

        let download = Download(episode: episode)
        download.task = downloadsSession.downloadTask(with: url)
        download.task?.resume()
        download.isDownloading = true
        activeDownloads[urlString] = download
    }
}

extension DownloadService : URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url else {
            return
        }
        
        let urlString = sourceURL.absoluteString
        let download = activeDownloads[urlString]
        activeDownloads[urlString] = nil
      
        let destinationURL = localFilePath(for: sourceURL)

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)

        do {
            try fileManager.copyItem(at: location, to: destinationURL)
            download?.episode.downloaded = true
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
        
        if let download = download {
            DispatchQueue.main.async {
                self.delegate?.shouldReloadRowFor(download: download)
            }
        }
    }
    
    func localFilePath(for url: URL) -> URL {
        return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url, let download = activeDownloads[url.absoluteString] else {
            return
        }

        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        print("PROGRESS: \(download.progress) FROM \(totalSize)")
        
        DispatchQueue.main.async {
            self.delegate?.shouldUpdateProgressFor(download: download)
        }
    }
}
