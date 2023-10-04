//
//  ThreadsListDataSource+DelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension ThreadsListDataSource : ThreadListTableViewCellDelegate {
    func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.originalMessage,
           let imageUrl = tableCellState.1.messageMedia?.url
        {
            let mediaKey = tableCellState.1.messageMedia?.mediaKey
            
            MediaLoader.loadImage(url: imageUrl, message: message, mediaKey: mediaKey, completion: { messageId, image in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: image
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func shouldLoadPdfDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.originalMessage,
           let url = tableCellState.1.messageMedia?.url,
           let mediaKey = tableCellState.1.messageMedia?.mediaKey
        {
            shouldLoadFileDataFor(
                messageId: messageId,
                and: rowIndex,
                message: message,
                url: url,
                mediaKey: mediaKey,
                isPdf: true
            )
        }
    }
    
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.originalMessage,
           let url = tableCellState.1.genericFile?.url,
           let mediaKey = tableCellState.1.genericFile?.mediaKey
        {
            shouldLoadFileDataFor(
                messageId: messageId,
                and: rowIndex,
                message: message,
                url: url,
                mediaKey: mediaKey,
                isPdf: false
            )
        }
    }
    
    func shouldLoadFileDataFor(
        messageId: Int,
        and rowIndex: Int,
        message: TransactionMessage,
        url: URL,
        mediaKey: String?,
        isPdf: Bool
    ) {
        MediaLoader.loadFileData(
            url: url,
            isPdf: isPdf,
            message: message,
            mediaKey: mediaKey,
            completion: { (messageId, data, fileInfo) in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: fileInfo.previewImage,
                    data: data,
                    fileInfo: fileInfo
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            },
            errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            }
        )
    }
    
    func shouldLoadVideoDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.originalMessage,
           let url = tableCellState.1.messageMedia?.url,
           let mediaKey = tableCellState.1.messageMedia?.mediaKey
        {
            MediaLoader.loadVideo(url: url, message: message, mediaKey: mediaKey, completion: { (messageId, data, image) in
                let updatedMediaData = MessageTableCellState.MediaData(
                    image: image,
                    data: data
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            }, errorCompletion: { messageId in
                let updatedMediaData = MessageTableCellState.MediaData(
                    failed: true
                )
                self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
            })
        }
    }
    
    func shouldLoadGiphyDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let url = tableCellState.1.messageMedia?.url
        {
            GiphyHelper.getGiphyDataFrom(url: url.absoluteString, messageId: messageId, completion: { (data, messageId) in
                DispatchQueue.main.async {
                    if let data = data {
                        let updatedMediaData = MessageTableCellState.MediaData(
                            image: data.gifImageFromData()
                        )
                        self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
                    } else {
                        let updatedMediaData = MessageTableCellState.MediaData(
                            failed: true
                        )
                        self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
                    }
                }
            })
        }
    }
    
    func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.originalMessage,
           let url = tableCellState.1.audio?.url,
           let mediaKey = tableCellState.1.audio?.mediaKey
        {
            
            MediaLoader.loadFileData(
                url: url,
                isPdf: false,
                message: message,
                mediaKey: mediaKey,
                completion: { (messageId, data, fileInfo) in
                    
                    if let duration = self.audioPlayerHelper.getAudioDuration(data: data) {
                        
                        let updatedMediaData = MessageTableCellState.MediaData(
                            image: nil,
                            data: data,
                            fileInfo: fileInfo,
                            audioInfo: MessageTableCellState.AudioInfo(
                                loading: false,
                                playing: false,
                                duration: duration,
                                currentTime: 0
                            )
                        )
                        
                        self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
                    }
                },
                errorCompletion: { messageId in
                    let updatedMediaData = MessageTableCellState.MediaData(
                        failed: true
                    )
                    self.updateMessageTableCellStateFor(rowIndex: rowIndex, messageId: messageId, with: updatedMediaData)
                }
            )
        }
    }
    
    func didTapMediaButtonFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let messageMedia = tableCellState.1.messageMedia, let mediaCached = mediaCached[messageId] {
            
            if messageMedia.isVideo, let data = mediaCached.data {
                delegate?.shouldGoToVideoPlayerFor(messageId: messageId, with: data)
            } else {
                delegate?.shouldGoToAttachmentViewFor(messageId: messageId, isPdf: messageMedia.isPdf)
            }
        }
    }
    
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int) {
        if
           let cacheData = mediaCached[messageId],
           let data = cacheData.data,
           let fileInfo = cacheData.fileInfo
        {
            if let url = MediaLoader.saveFileInMemory(data: data, name: fileInfo.fileName) {
                delegate?.shouldOpenActivityVCFor(url: url)
            }
        }
    }
}

extension ThreadsListDataSource {
    func updateMessageTableCellStateFor(
        rowIndex: Int,
        messageId: Int,
        with updatedCachedMedia: MessageTableCellState.MediaData
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            mediaCached[messageId] = updatedCachedMedia
            
            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                snapshot.reloadItems([tableCellState.1])
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }
    
    func getTableCellStateFor(
        messageId: Int? = nil,
        and rowIndex: Int? = nil
    ) -> (Int, ThreadTableCellState)? {
        
        var tableCellState: (Int, ThreadTableCellState)? = nil
        
        if let rowIndex = rowIndex, threadTableCellStateArray.count > rowIndex, threadTableCellStateArray[rowIndex].originalMessage?.id == messageId {
            return (rowIndex, threadTableCellStateArray[rowIndex])
        }
        
        for i in 0..<threadTableCellStateArray.count {
            if threadTableCellStateArray[i].originalMessage?.id == messageId {
                tableCellState = (i, threadTableCellStateArray[i])
                break
            }
        }
        
        return tableCellState
    }
}
