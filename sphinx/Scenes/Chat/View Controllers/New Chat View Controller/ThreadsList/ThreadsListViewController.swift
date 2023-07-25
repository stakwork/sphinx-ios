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
    }
    
    func setupViews() {
        threadsHeaderView.setDelegate(self)
    }
}

extension ThreadsListViewController : ThreadHeaderViewDelegate {
    func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
}
