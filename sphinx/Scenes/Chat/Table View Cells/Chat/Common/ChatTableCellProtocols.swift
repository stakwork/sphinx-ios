//
//  CommonPaymentTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

protocol MessageRowProtocol: class {
    var delegate: MessageCellDelegate? { get set }
    var audioDelegate: AudioCellDelegate? { get set }
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?)
}

protocol RowWithLinkPreviewProtocol: class {
    func rowWillDisappear()
}

protocol GroupActionRowProtocol: class {
    var delegate: GroupRowDelegate? { get set }
    func configureMessage(message: TransactionMessage)
}

protocol MediaUploadingCellProtocol: class {
    func isUploading() -> Bool
    func configureUploadingProgress(progress: Int, finishUpload: Bool)
}
