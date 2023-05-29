//
//  NewChatHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewChatHeaderView: UIView {
    
    @IBOutlet var contentView: UIView!

    @IBOutlet weak var chatHeaderView: ChatHeaderView!
    @IBOutlet weak var pinnedMessageView: PinnedMessageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("NewChatHeaderView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func checkRoute() {
        chatHeaderView.checkRoute()
    }
    
    func setChatInfoOnHeader() {
        chatHeaderView.setChatInfo()
    }
    
    func updateSatsEarnedOnHeader() {
        chatHeaderView.updateSatsEarned()
    }
    
    func configureHeaderWith(
        chat: Chat?,
        contact: UserContact?,
        andDelegate delegate: ChatHeaderViewDelegate
    ) {
        chatHeaderView.configureWith(
            chat: chat,
            contact: contact,
            delegate: delegate
        )
    }
    
    func configurePinnedMessageViewWith(
        chatId: Int,
        andDelegate delegate: PinnedMessageViewDelegate
    ) {
        pinnedMessageView.configureWith(
            chatId: chatId,
            and: delegate,
            completion: nil
        )
    }
}
