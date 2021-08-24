//
//  PodcastPaymentsHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

class PodcastPaymentsHelper {
    public static func getSatsEarnedFor(_ feedId: Int) -> Int {
        let pmts = TransactionMessage.getPaymentsFor(feedId: feedId)
        var satsEarned = 0
        
        for pmt in pmts {
            satsEarned += (pmt.amount?.intValue ?? 0)
        }
        return satsEarned
    }
    
    func processPaymentsFor(podcastFeed: PodcastFeed?,
                            boostAmount: Int? = nil,
                            itemId: Int,
                            currentTime: Int,
                            clipSenderPubKey: String? = nil,
                            uuid: String? = nil) {
        
        
        let suggestedAmount = getPodcastAmount(podcastFeed)
        let satsAmt = boostAmount ?? suggestedAmount
        let myPubKey = UserData.sharedInstance.getUserPubKey()
        var destinations = podcastFeed?.destinations ?? []
        var shouldUpdateMeta = true
        
        if
            let clipSenderPubKey = clipSenderPubKey,
            clipSenderPubKey != myPubKey
        {
            shouldUpdateMeta = false
            let clipSenderDestination = PodcastDestination(context: CoreDataManager.sharedManager.persistentContainer.viewContext)
            
            clipSenderDestination.address = clipSenderPubKey
            clipSenderDestination.split = 1
            clipSenderDestination.type = "node"
            
            podcastFeed?.addToDestinations(clipSenderDestination)
        }
        
        if let _ = boostAmount {
            shouldUpdateMeta = false
        }
        
        if
            let podcastFeed = podcastFeed,
            let chatId = podcastFeed.chat?.id,
            destinations.isEmpty == false
        {
            streamSats(
                podcastId: Int(podcastFeed.id),
                podcatsDestinations: destinations,
                updateMeta: shouldUpdateMeta,
                amount: satsAmt,
                chatId: chatId,
                itemId: itemId,
                currentTime: currentTime,
                uuid: uuid
            )
        }
    }
    
    func getPodcastAmount(_ podcastFeed: PodcastFeed?) -> Int {
        var suggestedAmount = (podcastFeed?.model?.suggestedSats) ?? 5
        
        if
            let chatId = podcastFeed?.chat?.id,
            let savedAmount = UserDefaults.standard.value(forKey: "podcast-sats-\(chatId)") as? Int,
                chatId > 0
        {
            suggestedAmount = savedAmount
        }
        
        return suggestedAmount
    }
    
    
    func getAmountFrom(sats: Double, split: Double) -> Int {
        max(1, Int(round(sats * (split/100))))
    }
    
    func getClipSenderAmt(sats: Double) -> Int {
        let amt = Int(round(sats * 0.01))
        return amt < 1 ? 1 : amt
    }
    
    func streamSats(podcastId: Int,
                    podcatsDestinations: [PodcastDestination],
                    updateMeta: Bool,
                    amount: Int,
                    chatId: Int,
                    itemId: Int,
                    currentTime: Int,
                    uuid: String? = nil) {
        
        var destinations = [[String: AnyObject]]()
        
        for d in podcatsDestinations {
            let destinationParams: [String: AnyObject] = ["address": (d.address ?? "") as AnyObject, "split": (d.split ?? 0) as AnyObject, "type": (d.type ?? "") as AnyObject]
            destinations.append(destinationParams)
        }
        
        var params: [String: AnyObject] = ["destinations": destinations as AnyObject, "amount": amount as AnyObject, "chat_id": chatId as AnyObject]
        params["update_meta"] = updateMeta as AnyObject
        
        if let uuid = uuid, !uuid.isEmpty {
            params["text"] = "{\"feedID\":\(podcastId),\"itemID\":\(itemId),\"ts\":\(currentTime),\"uuid\":\"\(uuid)\"}" as AnyObject
        } else {
            params["text"] = "{\"feedID\":\(podcastId),\"itemID\":\(itemId),\"ts\":\(currentTime)}" as AnyObject
        }
            
        API.sharedInstance.streamSats(params: params, callback: {}, errorCallback: {})
    }
}
