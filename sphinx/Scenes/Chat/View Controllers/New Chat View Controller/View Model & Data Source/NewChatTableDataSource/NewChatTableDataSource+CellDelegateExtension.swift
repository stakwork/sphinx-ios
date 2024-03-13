//
//  NewChatTableDataSource+CellDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import AVKit

///Loading content in background
extension NewChatTableDataSource : NewMessageTableViewCellDelegate {
    func shouldReplyToMessageWith(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message {
            
            if message.isReplyActionAllowed {
                delegate?.shouldReplyToMessage(message: message)
            }
        }
    }
    
    func shouldLoadTribeInfoFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let link = tableCellState.1.tribeLink?.link
        {
            if var tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: link) {
                API.sharedInstance.getTribeInfo(host: tribeInfo.host, uuid: tribeInfo.uuid, callback: { groupInfo in
                    
                    GroupsManager.sharedInstance.update(tribeInfo: &tribeInfo, from: groupInfo)
                    
                    self.updateMessageTableCellStateFor(
                        rowIndex: rowIndex,
                        messageId: messageId,
                        with: tribeInfo
                    )
                    
                }, errorCallback: {})
            }
        }
    }
    
    func shouldLoadLinkDataFor(messageId: Int, and rowIndex: Int) {
//        if var tableCellState = getTableCellStateFor(
//            messageId: messageId,
//            and: rowIndex
//        ),
//           let link = tableCellState.1.webLink?.link
//        {
//            if let cached = linkPreviewsLoader.cache.slp_getCachedResponse(url: link) {
//                updateMessageTableCellStateFor(
//                    rowIndex: rowIndex,
//                    messageId: messageId,
//                    with: MessageTableCellState.LinkData(
//                        link: link,
//                        icon: cached.icon,
//                        title: cached.title ?? "",
//                        description: cached.description ?? "",
//                        image: cached.image,
//                        failed: (
//                            cached.title == nil ||
//                            cached.description == nil ||
//                            cached.title?.isEmpty == true ||
//                            cached.description?.isEmpty == true
//                        )
//                    )
//                )
//            } else  {
//                linkPreviewsLoader.preview(link, onSuccess: { result in
//                    self.updateMessageTableCellStateFor(
//                        rowIndex: rowIndex,
//                        messageId: messageId,
//                        with: MessageTableCellState.LinkData(
//                            link: link,
//                            icon: result.icon,
//                            title: result.title ?? "",
//                            description: result.description ?? "",
//                            image: result.image,
//                            failed: (
//                                result.title == nil ||
//                                result.description == nil ||
//                                result.title?.isEmpty == true ||
//                                result.description?.isEmpty == true
//                            )
//                        )
//                    )
//                }, onError: { error in
//                    self.updateMessageTableCellStateFor(
//                        rowIndex: rowIndex,
//                        messageId: messageId,
//                        with: MessageTableCellState.LinkData(
//                            link: link,
//                            title: "",
//                            description: "",
//                            failed: true
//                        )
//                    )
//                })
//            }
//        }
    }
    
    func shouldLoadImageDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            
            var message = tableCellState.1.message
            var imageUrl = tableCellState.1.messageMedia?.url
            
            if messageId == tableCellState.1.threadOriginalMessage?.id {
                message = tableCellState.1.threadOriginalMessage
                imageUrl = tableCellState.1.threadOriginalMessageMedia?.url
            }
            
            guard let message = message, let imageUrl = imageUrl else {
                return
            }
            
            if message.isDirectPayment() {
                MediaLoader.loadPaymentTemplateImage(url: imageUrl, message: message, completion: { messageId, image in
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
            } else {
                var mediaKey = tableCellState.1.messageMedia?.mediaKey
                
                if messageId == tableCellState.1.threadOriginalMessage?.id {
                    mediaKey = tableCellState.1.threadOriginalMessageMedia?.mediaKey
                }
                
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
    }
    
    func shouldLoadPdfDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            
            var message = tableCellState.1.message
            var url = tableCellState.1.messageMedia?.url
            var mediaKey = tableCellState.1.messageMedia?.mediaKey
            
            if messageId == tableCellState.1.threadOriginalMessage?.id {
                message = tableCellState.1.threadOriginalMessage
                url = tableCellState.1.threadOriginalMessageMedia?.url
                mediaKey = tableCellState.1.threadOriginalMessageMedia?.mediaKey
            }
            
            guard let message = message, let url = url, let mediaKey = mediaKey else {
                return
            }
            
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
        ) {
            var message = tableCellState.1.message
            var url = tableCellState.1.genericFile?.url
            var mediaKey = tableCellState.1.genericFile?.mediaKey
            
            if messageId == tableCellState.1.threadOriginalMessage?.id {
                message = tableCellState.1.threadOriginalMessage
                url = tableCellState.1.threadOriginalMessageGenericFile?.url
                mediaKey = tableCellState.1.threadOriginalMessageGenericFile?.mediaKey
            }
            
            guard let message = message, let url = url, let mediaKey = mediaKey  else {
                return
            }
            
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
    
    func shouldLoadAudioDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            
            var message = tableCellState.1.message
            var url = tableCellState.1.audio?.url
            var mediaKey = tableCellState.1.audio?.mediaKey
            
            if messageId == tableCellState.1.threadOriginalMessage?.id {
                message = tableCellState.1.threadOriginalMessage
                url = tableCellState.1.threadOriginalMessageAudio?.url
                mediaKey = tableCellState.1.threadOriginalMessageAudio?.mediaKey
            }
            
            guard let message = message, let url = url, let mediaKey = mediaKey else {
                return
            }
            
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
        ) {
            
            var message = tableCellState.1.message
            var url = tableCellState.1.messageMedia?.url
            var mediaKey = tableCellState.1.messageMedia?.mediaKey
            
            if messageId == tableCellState.1.threadOriginalMessage?.id {
                message = tableCellState.1.threadOriginalMessage
                url = tableCellState.1.threadOriginalMessageMedia?.url
                mediaKey = tableCellState.1.threadOriginalMessageMedia?.mediaKey
            }
            
            guard let message = message, let url = url, let mediaKey = mediaKey else {
                return
            }
            
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
        ) {
            
            var url = tableCellState.1.messageMedia?.url
            
            if messageId == tableCellState.1.threadOriginalMessage?.id {
                url = tableCellState.1.threadOriginalMessageMedia?.url
            }
            
            guard let url = url else {
                return
            }
            
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
    
    func shouldLoadBotWebViewDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let html = tableCellState.1.botHTMLContent?.html
        {
            webViewSemaphore.wait()
            
            loadWebViewContent(
                html,
                completion: { height in
                    if let height = height {
                        self.botsWebViewData[messageId] = MessageTableCellState.BotWebViewData(height: height)
                        
                        DispatchQueue.main.async {
                            var snapshot = self.dataSource.snapshot()
                            snapshot.reloadItems([tableCellState.1])
                            self.dataSource.apply(snapshot, animatingDifferences: true)
                        }
                    }
                    
                    self.webViewSemaphore.signal()
                }
            )
        }
    }
    
    func shouldLoadTextDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.message
        {
            let urlAndMediaKey = tableCellState.1.messageMediaUrlAndKey
            
            if let url = urlAndMediaKey.0, let mediaKey = urlAndMediaKey.1 {
                MediaLoader.loadMessageData(
                    url: url,
                    message: message,
                    mediaKey: mediaKey,
                    completion: { (_, _) in },
                    errorCompletion: { _ in }
                )
            }
        }
    }
    
    func shouldPodcastCommentDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.message,
           let podcastComment = message.getPodcastComment()
        {
            if
                let feedId = podcastComment.feedId,
                let episodeId = podcastComment.itemId,
                let feed = ContentFeed.getFeedById(feedId: feedId)
            {
                let podcast = PodcastFeed.convertFrom(contentFeed: feed)
                    
                if let episode = podcast.getEpisodeWith(id: episodeId) {
                    if let duration = episode.duration {
                        updateWith(
                            duration: Double(duration),
                            currentTime: Double(podcastComment.timestamp ?? 0)
                        )
                    } else if let url = episode.getAudioUrl() {
                        let asset = AVAsset(url: url)
                        asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                            let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                            episode.duration = duration
                            
                            updateWith(
                                duration: Double(duration),
                                currentTime: Double(podcastComment.timestamp ?? 0)
                            )
                        })
                    }
                }
            }
        }
        
        func updateWith(
            duration: Double,
            currentTime: Double
        ) {
            let updatedMediaData = MessageTableCellState.MediaData(
                image: nil,
                data: nil,
                fileInfo: nil,
                audioInfo: MessageTableCellState.AudioInfo(
                    loading: false,
                    playing: false,
                    duration: duration,
                    currentTime: currentTime
                )
            )
            
            self.updateMessageTableCellStateFor(
                rowIndex: rowIndex,
                messageId: messageId,
                with: updatedMediaData
            )
        }
    }
}

///Updating rows after content loaded
extension NewChatTableDataSource {
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
            
            if rowIndex < 0 {
                self.delegate?.shouldReloadThreadHeaderView()
            } else {
                DispatchQueue.main.async {
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reloadItems([tableCellState.1])
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
            }
        }
    }
    
    func updateMessageTableCellStateFor(
        rowIndex: Int,
        messageId: Int,
        with tribeInfo: GroupsManager.TribeInfo
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let linkTribe = tableCellState.1.linkTribe
        {
            preloaderHelper.tribesData[linkTribe.uuid] = MessageTableCellState.TribeData(
                name: tribeInfo.name ?? "title.not.available".localized,
                description: tribeInfo.description ?? "description.not.available".localized,
                imageUrl: tribeInfo.img,
                showJoinButton: !linkTribe.isJoined,
                bubbleWidth:
                    (UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * (MessageTableCellState.kBubbleWidthPercentage)
            )

            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                snapshot.reloadItems([tableCellState.1])
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }
    
    func updateMessageTableCellStateFor(
        rowIndex: Int?,
        messageId: Int,
        with updatedUploadProgressData: MessageTableCellState.UploadProgressData
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            uploadingProgress[messageId] = updatedUploadProgressData
            
            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                snapshot.reloadItems([tableCellState.1])
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }
    
    func updateMessageTableCellStateFor(
        rowIndex: Int,
        messageId: Int,
        with linkData: MessageTableCellState.LinkData
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let linkWeb = tableCellState.1.linkWeb
        {
            preloaderHelper.linksData[linkWeb.link] = linkData

            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                snapshot.reloadItems([tableCellState.1])
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }
}

///Actions handling
extension NewChatTableDataSource {
    func didTapMessageReplyFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            if let messageReply = tableCellState.1.messageReply {
                if let replyingTableCellIndex = getTableCellStateFor(messageId: messageReply.messageId)?.0 {
                    tableView.scrollToRow(
                        at: IndexPath(row: replyingTableCellIndex, section: 0),
                        at: .top,
                        animated: true
                    )
                }
            }
        }
    }
    
    func didTapCallLinkCopyFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let link = tableCellState.1.callLink?.link {
            ClipboardHelper.copyToClipboard(text: link, message: "call.link.copied.clipboard".localized)
        }
    }
    
    func didTapCallJoinAudioFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let link = tableCellState.1.callLink?.link {
            startVideoCall(link: link, audioOnly: true)
        }
        delegate?.shouldDismissKeyboard()
    }
    
    func didTapCallJoinVideoFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let link = tableCellState.1.callLink?.link {
            startVideoCall(link: link, audioOnly: false)
        }
        
        delegate?.shouldDismissKeyboard()
    }
    
    func didTapMediaButtonFor(
        messageId: Int,
        and rowIndex: Int,
        isThreadOriginalMsg: Bool
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            let messageMedia = isThreadOriginalMsg ? tableCellState.1.threadOriginalMessageMedia : tableCellState.1.messageMedia
            
            if let messageMedia = messageMedia, let mediaCached = mediaCached[messageId] {
                if messageMedia.isVideo, let data = mediaCached.data {
                    delegate?.shouldGoToVideoPlayerFor(messageId: messageId, with: data)
                } else {
                    delegate?.shouldGoToAttachmentViewFor(messageId: messageId, isPdf: messageMedia.isPdf, webViewImageURL: nil)
                }
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
    
    func didTapTribeButtonFor(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let tribeLink = tableCellState.1.linkTribe {
            
            let joinLink = tribeLink.link
            delegate?.didTapOnTribeWith(joinLink: joinLink)
        }
    }
    
    func didTapContactButtonFor(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let contactLink = tableCellState.1.linkContact {
            delegate?.didTapOnContactWith(
                pubkey: contactLink.pubkey,
                and: contactLink.routeHint
            )
        }
    }
    
    func didTapOnLinkButtonFor(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let link = tableCellState.1.linkWeb?.link {
            didTapOnLink(link)
        }
    }
    
    func didTapDeleteTribeButtonFor(messageId: Int, and rowIndex: Int) {
        shouldDeleteGroup()
    }
    
    func didTapApproveRequestButtonFor(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message {
            shouldApproveMember(message: message)
        }
    }
    
    func didTapRejectRequestButtonFor(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message {
            shouldRejectMember(message: message)
        }
    }
    
    func didTapAvatarViewFor(messageId: Int, and rowIndex: Int) {
        guard let chat = chat else {
            return
        }
        
        if chat.isPublicGroup() {
            showLeaderboardFor(messageId: messageId)
        }
    }
    
    func didTapOnLink(_ link: String) {
        if
            !link.stringLinks.isEmpty ||
            !link.pubKeyMatches.isEmpty
        {
            if let link = link.stringFirstLink {
                if link.isPubKey {
                    delegate?.didTapOnContactWith(
                        pubkey: link.pubkeyComponents.0,
                        and: link.pubkeyComponents.1
                    )
                } else if link.isTribeJoinLink {
                    delegate?.didTapOnTribeWith(joinLink: link)
                } else if link.starts(with: API.kVideoCallServer) {
                    VideoCallManager.sharedInstance.startVideoCall(link: link)
                } else if let url = URL(string: link.withProtocol(protocolString: "http")) {
                    UIApplication.shared.open(
                        url,
                        options: [:],
                        completionHandler: nil
                    )
                }
            }
        }
    }
    
    func didTapPayButtonFor(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message {
            AttachmentsManager.sharedInstance.payAttachment(
                message: message,
                chat: chat,
                callback: { purchaseMessage in
                    if let _ = purchaseMessage {
                        return
                    }
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
                }
            )
        }
    }
    
    func didTapPlayPauseButtonFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if audioPlayerHelper.isPlayingMessageWith(messageId) {
            audioPlayerHelper.pausePlayingAudio()
        } else {
            if let audioData = mediaCached[messageId], let data = audioData.data {
                audioPlayerHelper.playAudioFrom(
                    data: data,
                    messageId: messageId,
                    rowIndex: rowIndex,
                    atTime: audioData.audioInfo?.currentTime,
                    delegate: self
                )
            }
        }
    }
    
    func didTapClipPlayPauseButtonFor(
        messageId: Int,
        and rowIndex: Int,
        atTime time: Double
    ) {
        podcastPlayerController.addDelegate(
            self,
            withKey: PodcastDelegateKeys.ChatDataSource.rawValue
        )
        
        updatePodcastInfoFor(
            loading: true,
            playing: false,
            duration: nil,
            currentTime: nil,
            messageId: messageId,
            rowIndex: rowIndex
        )
        
        if let podcastData = getPodcastDataFrom(
            messageId: messageId,
            and: rowIndex,
            atTime: time
        ) {
            if podcastPlayerController.isPlaying(messageId: messageId) {
                podcastPlayerController.submitAction(
                    UserAction.Pause(podcastData)
                )
            } else {
                podcastPlayerController.submitAction(
                    UserAction.Play(podcastData)
                )
            }
        }
    }
    
    func shouldSeekClipFor(
        messageId: Int,
        and rowIndex: Int,
        atTime time: Double
    ) {
        updatePodcastInfoFor(
            currentTime: time,
            messageId: messageId,
            rowIndex: rowIndex
        )
        
        if let podcastData = getPodcastDataFrom(
            messageId: messageId,
            and: rowIndex,
            atTime: time
        ) {
            podcastPlayerController.submitAction(
                UserAction.Seek(podcastData)
            )
        }
    }
    
    func getPodcastDataFrom(
        messageId: Int,
        and rowIndex: Int,
        atTime time: Double
    ) -> PodcastData? {
        
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.message,
           let podcastComment = message.getPodcastComment()
        {
            if
                let feedId = podcastComment.feedId,
                let episodeId = podcastComment.itemId,
                let feed = ContentFeed.getFeedById(feedId: feedId)
            {
                let podcast = PodcastFeed.convertFrom(contentFeed: feed)
                
                let clipInfo = PodcastData.ClipInfo(
                    messageId,
                    rowIndex,
                    message.uuid,
                    podcastComment.pubkey
                )
                
                return podcast.getPodcastData(
                    episodeId: episodeId,
                    currentTime: Int(time),
                    clipInfo: clipInfo
                )
            }
        }
        return nil
    }
    
    func didTapInvoicePayButtonFor(messageId: Int, and rowIndex: Int) {
        delegate?.shouldPayInvoiceFor(messageId: messageId)
    }
}

extension NewChatTableDataSource {
    func startVideoCall(link: String, audioOnly: Bool) {
        VideoCallManager.sharedInstance.startVideoCall(link: link, audioOnly: audioOnly)
    }
}

extension NewChatTableDataSource {
    func shouldDeleteGroup() {
        AlertHelper.showTwoOptionsAlert(
            title: "delete.tribe".localized,
            message: "confirm.delete.tribe".localized,
            confirmButtonTitle: "delete".localized,
            confirmStyle: .destructive,
            confirm: {
                self.deleteGroup()
            }
        )
    }
    
    func deleteGroup() {
        messageBubbleHelper.showLoadingWheel()
        guard let chat = chat else{
            return
        }
        SphinxOnionManager.sharedInstance.exitTribe(tribeChat: chat)
        DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
            CoreDataManager.sharedManager.deleteChatObjectsFor(chat)
            if let vc = self.delegate as? NewChatViewController{
                vc.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    func shouldApproveMember(message: TransactionMessage) {
        messageBubbleHelper.showLoadingWheel()
        guard let uuid = message.uuid,
        let chat = chat else{
            messageBubbleHelper.hideLoadingWheel()
            AlertHelper.showAlert(title: "Error", message: "There was an error with corrupted data from this request (invalid uuid)")
            return
        }
        SphinxOnionManager.sharedInstance.approveOrRejectTribeJoinRequest(requestUuid: uuid, chat: chat, type: TransactionMessage.TransactionMessageType.memberApprove)
        messageBubbleHelper.hideLoadingWheel()
    }
    
    func shouldRejectMember(message: TransactionMessage) {
        messageBubbleHelper.showLoadingWheel()
        
        guard let uuid = message.uuid,
        let chat = chat else{
            messageBubbleHelper.hideLoadingWheel()
            AlertHelper.showAlert(title: "Error", message: "There was an error with corrupted data from this request (invalid uuid)")
            return
        }
        SphinxOnionManager.sharedInstance.approveOrRejectTribeJoinRequest(requestUuid: uuid, chat: chat, type: TransactionMessage.TransactionMessageType.memberReject)
        messageBubbleHelper.hideLoadingWheel()
    }
    
    func requestResponseSucceddedWith(chat: Chat) {
        self.messageBubbleHelper.hideLoadingWheel()
        self.chat = chat
        self.delegate?.didUpdateChat(chat)
    }
    
    func requestResponseFailed() {
        self.messageBubbleHelper.hideLoadingWheel()
        self.showGenericError()
    }
    
    func showGenericError() {
        AlertHelper.showAlert(
            title: "generic.error.title".localized,
            message: "generic.error.message".localized
        )
    }
}

extension NewChatTableDataSource {
    func showLeaderboardFor(messageId: Int) {
        delegate?.shouldShowLeaderboardFor(messageId: messageId)
    }
}

///Menu Long press
extension NewChatTableDataSource {
    func didLongPressOn(cell: UITableViewCell, with messageId: Int, bubbleViewRect: CGRect) {
        if let indexPath = tableView.indexPath(for: cell) {
            if let tableCellState = getTableCellStateFor(
                messageId: messageId,
                and: indexPath.row
            ){
                var mutableTableCellState = tableCellState.1
                
                if mutableTableCellState.bubble?.grouping == .Empty {
                    return
                }
            }
        }
        delegate?.didLongPressOn(
            cell: cell,
            with: messageId,
            bubbleViewRect: bubbleViewRect,
            isThreadRow: messageIsThread(cell: cell, with: messageId)
        )
    }
    
    func messageIsThread(
        cell: UITableViewCell,
        with messageId: Int
    ) -> Bool {
        
        if let indexPath = tableView.indexPath(for: cell) {
            if let tableCellState = getTableCellStateFor(
                messageId: messageId,
                and: indexPath.row
            ){
                let mutableTableCellState = tableCellState.1
                return mutableTableCellState.isThread
            }
        }
        
        return false
    }
}

extension NewChatTableDataSource {
    func getTableCellStateFor(
        messageId: Int? = nil,
        and rowIndex: Int? = nil
    ) -> (Int, MessageTableCellState)? {
        
        var tableCellState: (Int, MessageTableCellState)? = nil
        
        ///Thread Header View
        if let rowIndex = rowIndex, rowIndex < 0 {
            if let threadHeaderMessageState = messageTableCellStateArray.last, threadHeaderMessageState.isThreadHeaderMessage {
                return (rowIndex, threadHeaderMessageState)
            }
        }
        
        if let rowIndex = rowIndex, messageTableCellStateArray.count > rowIndex, messageTableCellStateArray[rowIndex].message?.id == messageId {
            return (rowIndex, messageTableCellStateArray[rowIndex])
        }
        
        if let rowIndex = rowIndex, messageTableCellStateArray.count > rowIndex, messageTableCellStateArray[rowIndex].threadOriginalMessage?.id == messageId {
            return (rowIndex, messageTableCellStateArray[rowIndex])
        }
        
        for i in 0..<messageTableCellStateArray.count {
            if messageTableCellStateArray[i].message?.id == messageId {
                tableCellState = (i, messageTableCellStateArray[i])
                break
            }
        }
        
        return tableCellState
    }
    
    func getTableCellStatesForVisibleRows() -> [MessageTableCellState] {
        let rowIndexes = (tableView.indexPathsForVisibleRows ?? []).map({ $0.row })
        
        var tableCellStates: [MessageTableCellState] = []
        
        for rowIndex in rowIndexes {
            tableCellStates.append(
                messageTableCellStateArray[rowIndex]
            )
        }
        
        return tableCellStates
    }
}
