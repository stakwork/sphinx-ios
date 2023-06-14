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
        var tribeInfo: GroupsManager.TribeInfo?
        var isJoined: Bool
        
        init(
            link: String,
            tribeInfo: GroupsManager.TribeInfo?,
            isJoined: Bool
        ) {
            self.link = link
            self.tribeInfo = tribeInfo
            self.isJoined = isJoined
        }
        
        static func == (lhs: LinkTribe, rhs: LinkTribe) -> Bool {
            return lhs.link           == rhs.link &&
                   lhs.tribeInfo      == rhs.tribeInfo &&
                   lhs.isJoined       == rhs.isJoined
        }
    }
    
    struct MediaData: Equatable {
        var image: UIImage?
        var videoData: Data?
        var fileInfo: MessageTableCellState.FileInfo?
        var failed: Bool
        
        init(
            image: UIImage? = nil,
            videoData: Data? = nil,
            fileInfo: MessageTableCellState.FileInfo? = nil,
            failed: Bool = false
        ) {
            self.image = image
            self.videoData = videoData
            self.fileInfo = fileInfo
            self.failed = failed
        }
        
        static func == (lhs: MediaData, rhs: MediaData) -> Bool {
            return lhs.image           == rhs.image &&
                   lhs.videoData       == rhs.videoData &&
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
}
