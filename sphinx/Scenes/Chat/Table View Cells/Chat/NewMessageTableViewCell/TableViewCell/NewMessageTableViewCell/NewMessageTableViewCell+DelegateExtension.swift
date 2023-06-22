//
//  NewMessageTableViewCell+DelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewMessageTableViewCell : NewMessageReplyViewDelegate {
    func didTapMessageReplyView() {
        if let messageId = messageId {
            delegate?.didTapMessageReplyFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : JoinCallViewDelegate {
    func didTapCopyLink() {
        if let messageId = messageId {
            delegate?.didTapCallLinkCopyFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapAudioButton() {
        if let messageId = messageId {
            delegate?.didTapCallJoinAudioFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapVideoButton() {
        if let messageId = messageId {
            delegate?.didTapCallJoinVideoFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : MediaMessageViewDelegate {
    func didTapMediaButton() {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : FileDetailsViewDelegate {
    func didTapDownloadButton() {
        if let messageId = messageId {
            delegate?.didTapFileDownloadButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : LinkPreviewDelegate {
    func didTapOnTribeButton() {
        if let messageId = messageId {
            delegate?.didTapTribeButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapOnContactButton() {
        if let messageId = messageId {
            delegate?.didTapContactButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapOnWebLinkButton() {
        if let messageId = messageId {
            delegate?.didTapOnLinkButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : ChatAvatarViewDelegate {
    func didTapAvatarView() {
        if let messageId = messageId {
            delegate?.didTapAvatarViewFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let messageId = messageId {
            delegate?.didTapPayButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : AudioMessageViewDelegate {
    func didTapPlayPauseButton() {
        if let messageId = messageId {
            delegate?.didTapPlayPauseButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageTableViewCell : PodcastAudioViewDelegate {
    func didTapClipPlayPauseButton() {
        if let messageId = messageId {
            delegate?.didTapClipPlayPauseButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
