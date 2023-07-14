//
//  MessageTableCellState+DataTypeExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension MessageTableCellState {
    
    struct LinkContact {
        var pubkey: String
        var routeHint: String?
        var contact: UserContact?
        
        init(
            pubkey: String,
            routeHint: String?,
            contact: UserContact?
        ) {
            self.pubkey = pubkey
            self.routeHint = routeHint
            self.contact = contact
        }
    }
    
    struct LinkTribe {
        var link: String
        var uuid: String
        var isJoined: Bool
        
        init(
            link: String,
            uuid: String,
            isJoined: Bool
        ) {
            self.link = link
            self.uuid = uuid
            self.isJoined = isJoined
        }
    }
    
    struct LinkWeb {
        var link: String
        
        init(
            link: String
        ) {
            self.link = link
        }
    }
    
    struct LinkData {
        var link: String
        var icon: String?
        var title: String
        var description: String
        var image: String?
        var failed: Bool
        
        init(
            link: String,
            icon: String? = nil,
            title: String,
            description: String,
            image: String? = nil,
            failed: Bool
        ) {
            self.link = link
            self.icon = icon
            self.title = title
            self.description = description
            self.image = image
            self.failed = failed
        }
    }
    
    struct TribeData {
        var name: String
        var description: String
        var imageUrl: String?
        var showJoinButton: Bool
        var bubbleWidth: CGFloat
        
        init(
            name: String,
            description: String,
            imageUrl: String?,
            showJoinButton: Bool,
            bubbleWidth: CGFloat
        ) {
            self.name = name
            self.description = description
            self.imageUrl = imageUrl
            self.showJoinButton = showJoinButton
            self.bubbleWidth = bubbleWidth
        }
    }
    
    struct MediaData {
        var image: UIImage?
        var data: Data?
        var fileInfo: MessageTableCellState.FileInfo?
        var audioInfo: MessageTableCellState.AudioInfo?
        var failed: Bool
        
        init(
            image: UIImage? = nil,
            data: Data? = nil,
            fileInfo: MessageTableCellState.FileInfo? = nil,
            audioInfo: MessageTableCellState.AudioInfo? = nil,
            failed: Bool = false
        ) {
            self.image = image
            self.data = data
            self.fileInfo = fileInfo
            self.audioInfo = audioInfo
            self.failed = failed
        }
    }
    
    struct FileInfo {
        var fileSize: Int
        var fileName: String
        var pagesCount: Int?
        var previewImage: UIImage?
        
        init(
            fileSize: Int,
            fileName: String,
            pagesCount: Int?,
            previewImage: UIImage?
        ) {
            self.fileSize = fileSize
            self.fileName = fileName
            self.pagesCount = pagesCount
            self.previewImage = previewImage
        }
    }
    
    struct AudioInfo {
        var loading: Bool
        var playing: Bool
        var duration: Double
        var currentTime: Double
        
        init(
            loading: Bool,
            playing: Bool,
            duration: Double,
            currentTime: Double
        ) {
            self.loading = loading
            self.playing = playing
            self.duration = duration
            self.currentTime = currentTime
        }
    }
    
    struct MessageMenuData {
        var messageId: Int
        var bubbleRect: CGRect
        var indexPath: IndexPath
        
        init(
            messageId: Int,
            bubbleRect: CGRect,
            indexPath: IndexPath
        ) {
            self.messageId = messageId
            self.bubbleRect = bubbleRect
            self.indexPath = indexPath
        }
    }
    
    struct UploadProgressData {
        var progress: Int
        
        init(
            progress: Int
        ) {
            self.progress = progress
        }
    }
    
    struct BotWebViewData {
        var height: CGFloat
        
        init(
            height: CGFloat
        ) {
            self.height = height
        }
    }
}
