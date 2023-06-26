//
//  PodcastPaymentsHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

class PodcastPaymentsHelper {
    
    public static func getSatsEarnedFor(
        _ feedId: String
    ) -> Int {
        let pmts = TransactionMessage.getPaymentsFor(feedId: feedId)
        var satsEarned = 0
        
        for pmt in pmts {
            satsEarned += (pmt.amount?.intValue ?? 0)
        }
        return satsEarned
    }
    
    func processPaymentsFor(
        podcastFeed: PodcastFeed?,
        boostAmount: Int? = nil,
        itemId: String,
        currentTime: Int,
        clipSenderPubKey: String? = nil,
        uuid: String? = nil
    ) {
        let suggestedAmount = getPodcastAmount(podcastFeed)
        let satsAmt = boostAmount ?? suggestedAmount
        let myPubKey = UserData.sharedInstance.getUserPubKey()
        var destinations = podcastFeed?.destinationsArray ?? []
        var clipSenderDestination: PodcastDestination? = nil
        
        if
            let clipSenderPubKey = clipSenderPubKey,
            clipSenderPubKey != myPubKey
        {
            clipSenderDestination = PodcastDestination()
            
            if let clipSenderDestination = clipSenderDestination {
                clipSenderDestination.address = clipSenderPubKey
                clipSenderDestination.split = 1
                clipSenderDestination.type = "node"

                destinations.append(clipSenderDestination)
            }
        }
        
        if
            let podcastFeed = podcastFeed,
            !destinations.isEmpty
        {
            streamSats(
                podcastId: podcastFeed.feedID,
                podcastDestinations: destinations,
                updateMeta: false,
                amount: satsAmt,
                chatId: podcastFeed.chat?.id ?? -1,
                itemId: itemId,
                currentTime: currentTime,
                uuid: uuid
            )
        }
    }
    
    func getPodcastAmount(
        _ podcastFeed: PodcastFeed?
    ) -> Int {
        return podcastFeed?.satsPerMinute ?? podcastFeed?.model?.suggestedSats ?? 5
    }
    
    
    func getAmountFrom(
        sats: Double,
        split: Double
    ) -> Int {
        max(1, Int(round(sats * (split/100))))
    }
    
    func getClipSenderAmt(
        sats: Double
    ) -> Int {
        let amt = Int(round(sats * 0.01))
        return amt < 1 ? 1 : amt
    }
    
    func streamSats(
        podcastId: String,
        podcastDestinations: [PodcastDestination],
        updateMeta: Bool,
        amount: Int,
        chatId: Int,
        itemId: String,
        currentTime: Int,
        uuid: String? = nil
    ) {
        
        var destinations = [[String: AnyObject]]()
        
        for d in podcastDestinations {
            let destinationParams: [String: AnyObject] = [
                "address": (d.address ?? "") as AnyObject,
                "split": (d.split) as AnyObject,
                "type": (d.type ?? "") as AnyObject
            ]
            
            destinations.append(destinationParams)
        }
        
        var params: [String: AnyObject] = [
            "destinations": destinations as AnyObject,
            "amount": amount as AnyObject,
            "chat_id": chatId as AnyObject
        ]
        
        params["update_meta"] = updateMeta as AnyObject
        
        if let uuid = uuid, !uuid.isEmpty {
            params["text"] = "{\"feedID\":\"\(podcastId)\",\"itemID\":\"\(itemId)\",\"ts\":\(currentTime),\"uuid\":\"\(uuid)\"}" as AnyObject
        } else {
            params["text"] = "{\"feedID\":\"\(podcastId)\",\"itemID\":\"\(itemId)\",\"ts\":\(currentTime)}" as AnyObject
        }
            
        API.sharedInstance.streamSats(params: params, callback: {}, errorCallback: {})
    }
}
