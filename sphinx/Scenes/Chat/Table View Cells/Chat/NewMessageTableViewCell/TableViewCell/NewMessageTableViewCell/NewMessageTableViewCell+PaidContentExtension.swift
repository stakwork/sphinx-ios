//
//  NewMessageTableViewCell+PaidContentExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewMessageTableViewCell {
    func configureWith(
        paidContent: BubbleMessageLayoutState.PaidContent?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let paidContent = paidContent {
            if bubble.direction.isIncoming() {
                paidAttachmentView.configure(paidContent: paidContent, and: self)
                paidAttachmentView.isHidden = false
            } else {
                sentPaidDetailsView.configureWith(paidContent: paidContent)
                sentPaidDetailsView.isHidden = false
            }
            
            paidTextMessageView.isHidden = !paidContent.shouldAddPadding
        }
    }
}
