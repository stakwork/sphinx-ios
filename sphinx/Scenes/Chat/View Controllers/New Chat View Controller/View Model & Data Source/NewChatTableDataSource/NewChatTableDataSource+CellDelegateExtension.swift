//
//  NewChatTableDataSource+CellDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SwiftLinkPreview

///Loading content in background
extension NewChatTableDataSource : NewMessageTableViewCellDelegate {
    func shouldReplyToMessageWith(messageId: Int, and rowIndex: Int) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let message = tableCellState.1.message {
            delegate?.shouldReplyToMessage(message: message)
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
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let link = tableCellState.1.webLink?.link
        {
            if let cached = linkPreviewsLoader.cache.slp_getCachedResponse(url: link) {
                updateMessageTableCellStateFor(
                    rowIndex: rowIndex,
                    messageId: messageId,
                    with: MessageTableCellState.LinkData(
                        link: link,
                        icon: cached.icon,
                        title: cached.title ?? "",
                        description: cached.description ?? "",
                        image: cached.image,
                        failed: (cached.title == nil || cached.description == nil)
                    )
                )
            } else  {
                linkPreviewsLoader.preview(link, onSuccess: { result in
                    self.updateMessageTableCellStateFor(
                        rowIndex: rowIndex,
                        messageId: messageId,
                        with: MessageTableCellState.LinkData(
                            link: link,
                            icon: result.icon,
                            title: result.title ?? "",
                            description: result.description ?? "",
                            image: result.image,
                            failed: (result.title == nil || result.description == nil)
                        )
                    )
                }, onError: { error in
                    self.updateMessageTableCellStateFor(
                        rowIndex: rowIndex,
                        messageId: messageId,
                        with: MessageTableCellState.LinkData(
                            link: link,
                            title: "",
                            description: "",
                            failed: true
                        )
                    )
                })
            }
        }
    }
    
    func shouldLoadImageDataFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.message,
           let imageUrl = tableCellState.1.messageMedia?.url
        {
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
                MediaLoader.loadImage(url: imageUrl, message: message, completion: { messageId, image in
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
        ),
           let message = tableCellState.1.message,
           let url = tableCellState.1.messageMedia?.url
        {
            shouldLoadFileDataFor(
                messageId: messageId,
                and: rowIndex,
                message: message,
                url: url,
                isPdf: true
            )
        }
    }
    
    func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ),
           let message = tableCellState.1.message,
           let url = tableCellState.1.genericFile?.url
        {
            shouldLoadFileDataFor(
                messageId: messageId,
                and: rowIndex,
                message: message,
                url: url,
                isPdf: false
            )
        }
    }
    
    func shouldLoadFileDataFor(
        messageId: Int,
        and rowIndex: Int,
        message: TransactionMessage,
        url: URL,
        isPdf: Bool
    ) {
        MediaLoader.loadFileData(
            url: url,
            isPdf: isPdf,
            message: message,
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
           let message = tableCellState.1.message,
           let url = tableCellState.1.messageMedia?.url
        {
            MediaLoader.loadVideo(url: url, message: message, completion: { (messageId, data, image) in
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
    
    func shouldLoadBotWebViewDataFor(messageId: Int, and rowIndex: Int) {
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
                    self.botsWebViewData[messageId] = MessageTableCellState.BotWebViewData(height: height)
                    
                    DispatchQueue.main.async {
                        var snapshot = self.dataSource.snapshot()
                        snapshot.reloadItems([tableCellState.1])
                        self.dataSource.apply(snapshot, animatingDifferences: false)
                    }
                    
                    self.webViewSemaphore.signal()
                }
            )
        }
    }
}

///Updating rows after content loaded
extension NewChatTableDataSource {
    func updateMessageTableCellStateFor(
        rowIndex: Int,
        messageId: Int,
        with updatedMediaData: MessageTableCellState.MediaData
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            cachedMedia[messageId] = updatedMediaData
            
            DispatchQueue.main.async {
                var snapshot = self.dataSource.snapshot()
                snapshot.reloadItems([tableCellState.1])
                self.dataSource.apply(snapshot, animatingDifferences: false)
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
                self.dataSource.apply(snapshot, animatingDifferences: false)
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
                self.dataSource.apply(snapshot, animatingDifferences: false)
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
                self.dataSource.apply(snapshot, animatingDifferences: false)
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
    }
    
    func didTapMediaButtonFor(
        messageId: Int,
        and rowIndex: Int
    ) {
        if var tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ), let messageMedia = tableCellState.1.messageMedia, let cacheMedia = cachedMedia[messageId] {
            
            if messageMedia.isVideo, let data = cacheMedia.data {
                delegate?.shouldGoToVideoPlayerFor(messageId: messageId, with: data)
            } else {
                delegate?.shouldGoToAttachmentViewFor(messageId: messageId, isPdf: messageMedia.isPdf)
            }
        }
    }
    
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int) {
        if
           let cacheData = cachedMedia[messageId],
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
        if chat.isPublicGroup() {
            showLeaderboardFor(messageId: messageId)
        }
    }
    
    func didTapOnLink(_ link: String) {
        if
            !link.stringLinks.isEmpty ||
            !link.pubKeyMatches.isEmpty
        {
            if let joinLink = link.stringFirstTribeLink {
                delegate?.didTapOnTribeWith(joinLink: joinLink)
            } else if let contactLink = link.stringFirstPubKey {
                delegate?.didTapOnContactWith(
                    pubkey: contactLink.pubkeyComponents.0,
                    and: contactLink.pubkeyComponents.1
                )
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
        bubbleHelper.showLoadingWheel()
        
        GroupsManager.sharedInstance.deleteGroup(chat: self.chat, completion: { success in
            self.bubbleHelper.hideLoadingWheel()
            
            if success {
                self.delegate?.didDeleteTribe()
            } else {
                self.showGenericError()
            }
        })
    }
    
    func shouldApproveMember(message: TransactionMessage) {
        bubbleHelper.showLoadingWheel()
        
        GroupsManager.sharedInstance.respondToRequest(
            message: message,
            action: "approved",
            completion: { (chat, _) in
                self.requestResponseSucceddedWith(chat: chat)
            },
            errorCompletion: {
                self.requestResponseFailed()
            }
        )
    }
    
    func shouldRejectMember(message: TransactionMessage) {
        bubbleHelper.showLoadingWheel()
        
        GroupsManager.sharedInstance.respondToRequest(
            message: message,
            action: "rejected",
            completion: { (chat, _) in
                self.requestResponseSucceddedWith(chat: chat)
            },
            errorCompletion: {
                self.requestResponseFailed()
            }
        )
    }
    
    func requestResponseSucceddedWith(chat: Chat) {
        self.bubbleHelper.hideLoadingWheel()
        self.chat = chat
        self.delegate?.didUpdateChat(chat)
    }
    
    func requestResponseFailed() {
        self.bubbleHelper.hideLoadingWheel()
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
    func didLongPressOnCellWith(messageId: Int, and rowIndex: Int, bubbleViewRect: CGRect) {
        SoundsPlayer.playHaptic()
        
        delegate?.didLongPressOnCellWith(messageId: messageId, and: rowIndex, bubbleViewRect: bubbleViewRect)
    }
}

extension NewChatTableDataSource {
    func getTableCellStateFor(
        messageId: Int,
        and rowIndex: Int? = nil
    ) -> (Int, MessageTableCellState)? {
        
        var tableCellState: (Int, MessageTableCellState)? = nil
        
        if let rowIndex = rowIndex, messageTableCellStateArray[rowIndex].message?.id == messageId {
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
}
