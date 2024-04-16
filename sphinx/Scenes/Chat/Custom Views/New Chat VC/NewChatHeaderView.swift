//
//  NewChatHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewChatHeaderView: UIView {
    
    weak var searchDelegate: ChatSearchTextFieldViewDelegate?
    
    @IBOutlet var contentView: UIView!

    @IBOutlet weak var normalModeStackView: UIStackView!
    @IBOutlet weak var chatHeaderView: ChatHeaderView!
    @IBOutlet weak var pinnedMessageView: PinnedMessageView!
    @IBOutlet weak var threadHeaderView: ThreadHeaderView!
    @IBOutlet weak var chatSearchView: ChatSearchTextFieldView!
    
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
    
    func toggleWebAppIcon(showChatIcon: Bool) {
        chatHeaderView.toggleWebAppIcon(showChatIcon: showChatIcon)
    }
    
    func toggleSBIcon(showChatIcon: Bool) {
        chatHeaderView.toggleSBIcon(showChatIcon: showChatIcon)
    }
    
    func configureHeaderWith(
        chat: Chat?,
        contact: UserContact?,
        andDelegate delegate: ChatHeaderViewDelegate,
        searchDelegate: ChatSearchTextFieldViewDelegate? = nil
    ) {
        chatHeaderView.configureWith(
            chat: chat,
            contact: contact,
            delegate: delegate
        )
        
        self.searchDelegate = searchDelegate
        
        chatSearchView.setDelegate(self)
    }
    
    func configureThreadHeaderWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        delegate: ThreadHeaderViewDelegate
    ) {
        threadHeaderView.configureWith(
            messageCellState: messageCellState,
            mediaData: mediaData,
            delegate: delegate
        )
        threadHeaderView.isHidden = false
        
        normalModeStackView.isHidden = true
        chatSearchView.isHidden = true
    }
    
    func showThreadHeaderView() {
        threadHeaderView.isHidden = false
        
        normalModeStackView.isHidden = true
        chatSearchView.isHidden = true
    }
    
    func toggleThreadHeaderView(expanded: Bool) {
        threadHeaderView.toggleThreadHeaderView(expanded: expanded)
    }
    
    func configurePinnedMessageViewWith(
        chatId: Int,
        andDelegate delegate: PinnedMessageViewDelegate,
        completion: (() ->())? = nil
    ) {
        pinnedMessageView.configureWith(
            chatId: chatId,
            and: delegate,
            completion: completion
        )
    }
    
    func configureSearchMode(
        active: Bool
    ) {
        normalModeStackView.isHidden = active
        chatSearchView.isHidden = !active
        
        if active {
            chatSearchView.makeFieldActive()
        }
    }
}

extension NewChatHeaderView : ChatSearchTextFieldViewDelegate {
    func shouldSearchFor(term: String) {
        searchDelegate?.shouldSearchFor(term: term)
    }
    
    func didTapSearchCancelButton() {
        configureSearchMode(active: false)
        
        searchDelegate?.didTapSearchCancelButton()
    }
}
