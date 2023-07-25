//
//  ThreadsListViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/07/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ThreadsListViewController: PopHandlerViewController {

    @IBOutlet weak var threadsHeaderView: ThreadsListHeaderView!
    @IBOutlet weak var shimmeringView: ShimmeringList!
    @IBOutlet weak var threadsTableView: UITableView!
    @IBOutlet weak var noResultsFoundLabel: UITableView!
    
    var threadsListDataSource: ThreadsListDataSource? = nil
    
    var chat: Chat?
    
    static func instantiate(
        chatId: Int
    ) -> ThreadsListViewController {
        let viewController = StoryboardScene.Chat.threadsListViewController.instantiate()
        
        viewController.chat = Chat.getChatWith(id: chatId)
        viewController.popOnSwipeEnabled = true
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        configureTableView()
    }
    
    func setupViews() {
        threadsHeaderView.setDelegate(self)
    }
    
    func configureTableView() {
        guard let chat = chat else {
            return
        }
        
        threadsListDataSource = ThreadsListDataSource(
            chat: chat,
            tableView: threadsTableView,
            delegate: self
        )
    }
}

extension ThreadsListViewController : ThreadHeaderViewDelegate {
    func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
}

extension ThreadsListViewController : ThreadsListDataSourceDelegate {
    func didSelectThreadWith(uuid: String) {
        let chatVC = NewChatViewController.instantiate(
            chatId: self.chat?.id,
            threadUUID: uuid
        )
        
        navigationController?.pushViewController(
            chatVC,
            animated: true
        )
    }
}
