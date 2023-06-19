//
//  NewChatViewModel.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import ObjectMapper

class NewChatViewModel {
    
    var chat: Chat?
    var contact: UserContact?
    var chatDataSource: NewChatTableDataSource? = nil
    
    var chatLeaderboard : [ChatLeaderboardEntry] = [ChatLeaderboardEntry]()
    var availableBadges : [Badge] = [Badge]()
    
    var podcastComment: PodcastComment? = nil
    var replyingTo: TransactionMessage? = nil
    
    init(
        chat: Chat?,
        contact: UserContact?
    ) {
        self.chat = chat
        self.contact = contact
    }
    
    func setDataSource(_ dataSource: NewChatTableDataSource?) {
        self.chatDataSource = dataSource
    }
    
    ///Notifications
    func askForNotificationPermissions() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.registerForPushNotifications()
    }
    
    ///Volume
    func toggleVolume(
        completion: @escaping (Chat?) -> ()
    ) {
        guard let chat = chat else {
            return
        }
        
        let currentMode = chat.isMuted()
        
        API.sharedInstance.toggleChatSound(chatId: chat.id, muted: !currentMode, callback: { chatJson in
            if let updatedChat = Chat.insertChat(chat: chatJson) {
                completion(updatedChat)
            }
        }, errorCallback: {
            completion(nil)
        })
    }
    
    ///Leaderboard and badges
    func loadBadgesAndLeaderboard() {
        getChatLeaderboards()
        getChatBadges()
    }
    
    func getChatLeaderboards() {
        if let uuid = chat?.tribeInfo?.uuid {
            API.sharedInstance.getTribeLeaderboard(
                tribeUUID: uuid,
                callback: { results in
                    if let chatLeaderboardEntries = Mapper<ChatLeaderboardEntry>().mapArray(JSONObject: Array(results)) {
                        self.chatLeaderboard = chatLeaderboardEntries
                    }
                },
                errorCallback: {}
            )
        }
    }
    
    func getChatBadges(){
        if let chat = chat, let tribeInfo = chat.tribeInfo {
            API.sharedInstance.getAssetsByID(
                assetIDs: tribeInfo.badgeIds,
                callback: { results in
                    self.availableBadges = results
                },
                errorCallback: {}
            )
        }
    }
    
    func getLeaderboardEntryFor(message: TransactionMessage) -> ChatLeaderboardEntry? {
        return chatLeaderboard.filter({ $0.alias == message.senderAlias }).first
    }
    
    ///Mentions
    func getMentionsFrom(mentionText: String) -> [String] {
        var possibleMentions = [String]()
        
        if mentionText.count > 0 {
            possibleMentions = self.chat?.aliases.filter({
                if (mentionText.count > $0.count) {
                    return false
                }
                let substring = $0.substring(range: NSRange(location: 0, length: mentionText.count))
                return (substring.lowercased() == mentionText && mentionText != "")
            }).sorted() ?? []
        }
        
        return possibleMentions
    }
    
    ///Reply view
    func resetReply() {
        podcastComment = nil
        replyingTo = nil
    }
}
