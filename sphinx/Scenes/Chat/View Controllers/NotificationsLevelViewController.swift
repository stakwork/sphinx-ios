//
//  NotificationsLevelViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

public protocol PresentedViewControllerDelegate: class {
    func viewWillDismiss()
}

class NotificationsLevelViewController: UIViewController {
    
    public weak var delegate: PresentedViewControllerDelegate?
    
    var chat: Chat!
    
    @IBOutlet weak var tableView: UITableView!
    
    let kRowHeight: CGFloat = 44
    
    var notificationLevelOptions: [NotificationLevel] = [
        NotificationLevel(title: "See all", selected: true),
        NotificationLevel(title: "Only mentions", selected: false),
        NotificationLevel(title: "Mute chat", selected: false)
    ]
    
    struct NotificationLevel {
        var title = ""
        var selected = false
        
        init(title: String, selected: Bool) {
            self.title = title
            self.selected = selected
        }
    }
    
    static func instantiate(
        chat: Chat,
        delegate: NotificationsLevelViewControllerDelegate?
    ) -> NotificationsLevelViewController {
        let viewController = StoryboardScene.Chat.notificationsLevelViewController.instantiate()
        viewController.chat = chat
        viewController.delegate = delegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        configureViewFromChat()
    }
    
    func configureViewFromChat() {
        notificationLevelOptions = [
            NotificationLevel(title: "See all", selected: chat.notify == Chat.NotificationLevel.SeeAll.rawValue),
            NotificationLevel(title: "Only mentions", selected: chat.notify == Chat.NotificationLevel.OnlyMentions.rawValue),
            NotificationLevel(title: "Mute chat", selected: chat.notify == Chat.NotificationLevel.MuteChat.rawValue)
        ]
        tableView.reloadData()
    }
    
    func setChatNotificationLevel(_ level: Int) {
        API.sharedInstance.setNotificationLevel(chatId: chat.id, level: level, callback: { chatJson in
            if let updatedChat = Chat.insertChat(chat: chatJson) {
                self.chat = updatedChat
            }
            self.configureViewFromChat()
        }, errorCallback: {
            self.configureViewFromChat()
        })
    }
    
    @IBAction func closeButtonTouched() {
        self.delegate?.viewWillDismiss()
        self.dismiss(animated: true)
    }
}

extension NotificationsLevelViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kRowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? NotificationLevelTableViewCell {
            let level = notificationLevelOptions[indexPath.row]
            cell.configureCell(notificationLevel: level)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setChatNotificationLevel(indexPath.row)
        
        notificationLevelOptions = [
            NotificationLevel(title: "See all", selected: indexPath.row == Chat.NotificationLevel.SeeAll.rawValue),
            NotificationLevel(title: "Only mentions", selected: indexPath.row == Chat.NotificationLevel.OnlyMentions.rawValue),
            NotificationLevel(title: "Mute chat", selected: indexPath.row == Chat.NotificationLevel.MuteChat.rawValue)
        ]
        
        tableView.reloadData()
    }
}

extension NotificationsLevelViewController : UITableViewDataSource {
    func getRowsCount() -> Int {
        return notificationLevelOptions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getRowsCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationLevelTableViewCell", for: indexPath) as! NotificationLevelTableViewCell
        return cell
    }
}
