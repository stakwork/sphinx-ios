//
//  MessageTableCellState+DataTypeExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension MessageTableCellState {
    
    struct LinkContact: Equatable {
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
        
        static func == (lhs: LinkContact, rhs: LinkContact) -> Bool {
            return lhs.pubkey         == rhs.pubkey &&
                   lhs.routeHint      == rhs.routeHint &&
                   lhs.contact?.id    == rhs.contact?.id
        }
    }
    
    struct LinkTribe: Equatable {
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
        
        static func == (lhs: LinkTribe, rhs: LinkTribe) -> Bool {
            return lhs.link           == rhs.link &&
                   lhs.uuid           == rhs.uuid &&
                   lhs.isJoined       == rhs.isJoined
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
    
    struct MediaData: Equatable {
        var image: UIImage?
        var data: Data?
        var fileInfo: MessageTableCellState.FileInfo?
        var failed: Bool
        
        init(
            image: UIImage? = nil,
            data: Data? = nil,
            fileInfo: MessageTableCellState.FileInfo? = nil,
            failed: Bool = false
        ) {
            self.image = image
            self.data = data
            self.fileInfo = fileInfo
            self.failed = failed
        }
        
        static func == (lhs: MediaData, rhs: MediaData) -> Bool {
            return lhs.image           == rhs.image &&
                   lhs.data            == rhs.data &&
                   lhs.fileInfo        == rhs.fileInfo &&
                   lhs.failed          == rhs.failed
        }
    }
    
    struct FileInfo: Equatable {
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
        
        static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
            return lhs.fileSize           == rhs.fileSize &&
                   lhs.fileName           == rhs.fileName &&
                   lhs.pagesCount         == rhs.pagesCount
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
    
    struct UploadProgressData: Equatable {
        var progress: Int
        
        init(
            progress: Int
        ) {
            self.progress = progress
        }
        
        static func == (lhs: UploadProgressData, rhs: UploadProgressData) -> Bool {
            return lhs.progress       == rhs.progress
        }
    }
}
