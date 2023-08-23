//
//  MediaLoader.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SDWebImage
import AVFoundation
import Photos

class MediaLoader {
    
    static let cache = SphinxCache()
    
    class func loadDataFrom(
        URL: URL,
        includeToken: Bool = true,
        completion: @escaping (Data, String?) -> (),
        errorCompletion: @escaping () -> ()
    ) {
        if !ConnectivityHelper.isConnectedToInternet {
            errorCompletion()
            return
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: URL as URL)
        
        if let token: String = UserDefaults.Keys.attachmentsToken.get(), includeToken {
            request.addValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        request.httpMethod = "GET"
        
        let task = session.dataTask(
            with: request,
            completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if let _ = error {
                    errorCompletion()
                } else if (response as? HTTPURLResponse)?.statusCode == API.sharedInstance.unauthorizedStatusCode {
                    errorCompletion()
                } else if let data = data {
                    completion(data, response?.getFileName())
                }
            }
        )
        
        task.resume()
    }
    
    class func asyncLoadImage(
        imageView: UIImageView,
        nsUrl: URL,
        placeHolderImage: UIImage?,
        completion: (() -> ())? = nil
    ) {
        imageView.sd_setImage(
            with: nsUrl,
            placeholderImage: placeHolderImage,
            options: SDWebImageOptions.progressiveLoad,
            completed: { (image, error, _, _) in
                if let completion = completion, let _ = image {
                    completion()
                }
            }
        )
    }
    
    class func asyncLoadImage(
        imageView: UIImageView,
        nsUrl: URL,
        placeHolderImage: UIImage?,
        completion: @escaping ((UIImage) -> ()),
        errorCompletion: ((Error) -> ())? = nil
    ) {
        imageView.sd_setImage(
            with: nsUrl,
            placeholderImage: placeHolderImage,
            options: SDWebImageOptions.progressiveLoad,
            completed: { (image, error, _, _) in
                if let image = image {
                    completion(image)
                } else if let errorCompletion = errorCompletion, let error = error {
                    errorCompletion(error)
                }
            }
        )
    }
    
    class func asyncLoadImage(
        imageView: UIImageView,
        nsUrl: URL,
        placeHolderImage: UIImage?,
        id: Int,
        completion: @escaping ((UIImage, Int) -> ()),
        errorCompletion: ((Error) -> ())? = nil
    ) {
        imageView.sd_setImage(
            with: nsUrl,
            placeholderImage: placeHolderImage,
            options: SDWebImageOptions.progressiveLoad,
            completed: { (image, error, _, _) in
                if let image = image {
                    completion(image, id)
                } else if let errorCompletion = errorCompletion, let error = error {
                    errorCompletion(error)
                }
            }
        )
    }
    
    class func loadImage(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, UIImage) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        let isGif = message.isGif()
        
        if message.isMediaExpired() {
            clearImageCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
            return
        } else if let cachedImage = getImageFromCachedUrl(url: url.absoluteString) {
            if !isGif || (isGif && getMediaDataFromCachedUrl(url: url.absoluteString) != nil) {
                DispatchQueue.main.async {
                    completion(messageId, cachedImage)
                }
                return
            }
        }
        
        loadDataFrom(URL: url, completion: { (data, fileName) in
            message.saveFileName(fileName)
            
            DispatchQueue.main.async {
                loadImageFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: completion,
                    errorCompletion: errorCompletion
                )
            }
        }, errorCompletion: {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        })
    }
    
    class func loadImageFromData(
        data: Data,
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, UIImage) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        let isGif = message.isGif()
        let isPDF = message.isPDF()
        var decryptedImage:UIImage? = nil
        
        if let image = UIImage(data: data) {
            decryptedImage = image
        } else if let mediaKey = mediaKey, mediaKey != "" {
            if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                message.saveFileSize(decryptedData.count)
                
                if isGif || isPDF {
                    storeMediaDataInCache(data: decryptedData, url: url.absoluteString)
                }
                decryptedImage = getImageFromData(decryptedData, isPdf: isPDF)
            }
        }
        
        if let decryptedImage = decryptedImage {
            storeImageInCache(
                img: decryptedImage,
                url: url.absoluteString,
                message: message
            )
            
            DispatchQueue.main.async {
                completion(messageId, decryptedImage)
            }
        } else {
            DispatchQueue.main.async {
                errorCompletion(messageId)
            }
        }
    }
    
    class func getImageFromData(
        _ data: Data,
        isPdf: Bool
    ) -> UIImage? {
        if isPdf {
            if let image = data.getPDFThumbnail() {
                return image
            }
        }
        return UIImage(data: data)
    }
    
    class func loadMessageData(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, String) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        loadDataFrom(URL: url, completion: { (data, _) in
            if let mediaKey = mediaKey, mediaKey.isNotEmpty {
                if let data = SymmetricEncryptionManager.sharedInstance.decryptData(data: data, key: mediaKey) {
                    let str = String(decoding: data, as: UTF8.self)
                    if str != "" {
                        DispatchQueue.main.async {
                            message.messageContent = str
                            
                            completion(
                                message.id,
                                str
                            )
                        }
                        return
                    }
                }
            }
            DispatchQueue.main.async {
                errorCompletion(message.id)
            }
        }, errorCompletion: {
            DispatchQueue.main.async {
                errorCompletion(message.id)
            }
        })
    }
    
    class func loadVideo(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, Data, UIImage?) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearImageCacheFor(url: url.absoluteString)
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            let image = self.getImageFromCachedUrl(url: url.absoluteString) ?? nil
            if image == nil {
                self.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
                    DispatchQueue.main.async {
                        completion(messageId, data, image)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(messageId, data, image)
                }
            }
        } else {
            loadDataFrom(URL: url, completion: { (data, fileName) in
                message.saveFileName(fileName)
                
                self.loadMediaFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    isVideo: true,
                    completion: { data in
                        self.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
                            DispatchQueue.main.async {
                                completion(messageId, data, image)
                            }
                        })
                    },
                    errorCompletion: errorCompletion
                )
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadFileData(
        url: URL,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, Data) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            DispatchQueue.main.async {
                completion(messageId, data)
            }
        } else {
            loadDataFrom(URL: url, completion: { (data, fileName) in
                message.saveFileName(fileName)
                
                self.loadMediaFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: { data in
                        DispatchQueue.main.async {
                            completion(messageId, data)
                        }
                    },
                    errorCompletion: errorCompletion
                )
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadFileData(
        url: URL,
        isPdf: Bool,
        message: TransactionMessage,
        mediaKey: String?,
        completion: @escaping (Int, Data, MessageTableCellState.FileInfo) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        let messageId = message.id
        
        if message.isMediaExpired() {
            clearMediaDataCacheFor(url: url.absoluteString)
            errorCompletion(messageId)
        } else if let data = getMediaDataFromCachedUrl(url: url.absoluteString) {
            
            let fileInfo = MessageTableCellState.FileInfo(
                fileSize: message.mediaFileSize,
                fileName: message.mediaFileName ?? "",
                pagesCount: isPdf ? data.getPDFPagesCount() : nil,
                previewImage: isPdf ? data.getPDFThumbnail() : nil
            )
            
            DispatchQueue.main.async {
                completion(
                    messageId,
                    data,
                    fileInfo
                )
            }
        } else {
            loadDataFrom(URL: url, completion: { (data, fileName) in
                message.saveFileName(fileName)
                
                self.loadMediaFromData(
                    data: data,
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: { data in
                        let fileInfo = MessageTableCellState.FileInfo(
                            fileSize: message.mediaFileSize,
                            fileName: message.mediaFileName ?? "",
                            pagesCount: isPdf ? data.getPDFPagesCount() : nil,
                            previewImage: isPdf ? data.getPDFThumbnail() : nil
                        )
                        
                        DispatchQueue.main.async {
                            completion(messageId, data, fileInfo)
                        }
                    },
                    errorCompletion: errorCompletion
                )
            }, errorCompletion: {
                DispatchQueue.main.async {
                    errorCompletion(messageId)
                }
            })
        }
    }
    
    class func loadMediaFromData(
        data: Data,
        url: URL, message: TransactionMessage,
        mediaKey: String? = nil,
        isVideo: Bool = false,
        completion: @escaping (Data) -> (),
        errorCompletion: @escaping (Int) -> ()
    ) {
        if let mediaKey = mediaKey, mediaKey != "" {
            
            if let decryptedData = SymmetricEncryptionManager.sharedInstance.decryptData(
                data: data,
                key: mediaKey
            ) {
                message.saveFileSize(decryptedData.count)

                storeMediaDataInCache(
                    data: decryptedData,
                    url: url.absoluteString,
                    message: message
                )

                DispatchQueue.main.async {
                    completion(decryptedData)
                }
                return
            }
        } else {
            storeMediaDataInCache(
                data: data,
                url: url.absoluteString
            )
            
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    class func loadTemplate(
        row: Int,
        muid: String,
        completion: @escaping (Int, String, UIImage) -> ()
    ) {
        let urlString = "\(API.kAttachmentsServerUrl)/template/\(muid)"
        
        if let url = URL(string: urlString) {
            if let cachedImage = getImageFromCachedUrl(url: url.absoluteString) {
                completion(row, muid, cachedImage)
            } else {
                loadDataFrom(URL: url, includeToken: true, completion: { (data, _) in
                    if let image = UIImage(data: data) {
                        self.storeImageInCache(
                            img: image,
                            url: url.absoluteString,
                            message: nil
                        )
                        
                        DispatchQueue.main.async {
                            completion(row, muid, image)
                        }
                        return
                    }
                }, errorCompletion: {})
            }
        }
    }
    
    class func loadPaymentTemplateImage(
        url: URL,
        message: TransactionMessage,
        completion: @escaping (Int, UIImage) -> (), errorCompletion: @escaping (Int) -> ()
    ) {
        if let cachedImage = getImageFromCachedUrl(url: url.absoluteString) {
            completion(message.id, cachedImage)
        } else {
            loadDataFrom(URL: url, includeToken: true, completion: { (data, _) in
                if let image = UIImage(data: data) {
                    self.storeImageInCache(
                        img: image,
                        url: url.absoluteString,
                        message: nil
                    )
                    
                    DispatchQueue.main.async {
                        completion(message.id, image)
                    }
                    return
                }
            }, errorCompletion: {})
        }
    }
    
    class func getDataFromUrl(
        url: URL
    ) -> Data? {
        var data: Data?
        do {
            data = try Data(contentsOf: url as URL, options: Data.ReadingOptions.alwaysMapped)
        } catch _ {
            data = nil
        }
        
        guard let data = data else {
            return nil
        }
        return data
    }
    
    class func saveFileInMemory(
        data: Data,
        name: String
    ) -> URL? {
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        url.appendPathComponent(name)
        do {
            try data.write(to: url)
        } catch {
            return nil
        }
        return url
    }
    
    class func getThumbnailImageFromVideoData(
        data: Data,
        videoUrl: String,
        completion: @escaping ((_ image: UIImage?)->Void)
    ) {
        if let url = saveFileInMemory(data: data, name: "video.mov") {
            let asset = AVAsset(url: url)
            
            DispatchQueue.global().async {
                let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                avAssetImageGenerator.appliesPreferredTrackTransform = true
                let thumnailTime = CMTimeMake(value: 5, timescale: 1)
                do {
                    let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                    let thumbImage = UIImage(cgImage: cgThumbImage)
                    deleteItemAt(url: url)
                    
                    storeImageInCache(
                        img: thumbImage,
                        url: videoUrl,
                        message: nil
                    )
                    
                    DispatchQueue.main.async {
                        completion(thumbImage)
                    }
                } catch {
                    deleteItemAt(url: url)
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
    
    class func clearMessageMediaCache(message: TransactionMessage) {
        if let url = message.getPurchaseAcceptItem()?.getMediaUrlFromMediaToken() ?? message.getMediaUrlFromMediaToken() {
            clearImageCacheFor(url: url.absoluteString)
            clearMediaDataCacheFor(url: url.absoluteString)
        }
    }
    
    class func clearImageCacheFor(url: String) {
        SDImageCache.shared.removeImage(forKey: url, withCompletion: nil)
        cache.removeValue(forKey: url)
        
    }
    
    class func storeImageInCache(
        img: UIImage,
        url: String,
        message: TransactionMessage? = nil
    ) {
        SDImageCache.shared.store(img, forKey: url, completion: nil)
        
        if
            let message = message,
            let chat = message.chat?.getChat(),
            let path = getDiskImagePath(forKey: url)
        {
            
            let randomInt = Int.random(in: 0...Int(1e9))
            let name = message.getFileName()
            
            let _ = CachedMedia.createObject(
                id: randomInt,
                chat: chat,
                filePath: path,
                fileExtension: "png",
                key: url,
                fileName: name
            )
        }
    }
    
    class func getDiskImagePath(forKey key: String)->String? {
        return SDImageCache.shared.cachePath(forKey: key)
    }
    
    class func getImageFromCachedUrl(url: String) -> UIImage? {
        return SDImageCache.shared.imageFromCache(forKey: url)
    }
    
    class func storeMediaDataInCache(
        data: Data,
        url: String,
        message: TransactionMessage? = nil
    ) {
        cache[url] = data
        
        if
            let message = message,
            let chat = message.chat?.getChat(),
            let path = getDiskImagePath(forKey: url)
        {
            let randomInt = Int.random(in: 0...Int(1e9))
            let fileExtension = message.getCMExtensionAssignment()
            let name = message.getFileName()
            
            let _ = CachedMedia.createObject(
                id: randomInt,
                chat: chat,
                filePath: path,
                fileExtension: fileExtension,
                key: url,
                fileName: name
            )
        }
    }
    
    class func getMediaDataFromCachedUrl(url: String) -> Data? {
        return cache[url]
    }
    
    class func clearMediaDataCacheFor(url: String) {
        return cache.removeValue(forKey: url)
    }
        
    class func deleteItemAt(url: URL) {
        do {
            try FileManager().removeItem(at: url)
        } catch {
            
        }
    }
}
