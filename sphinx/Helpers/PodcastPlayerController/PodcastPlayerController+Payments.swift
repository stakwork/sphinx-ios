//
//  PodcastPlayerController+Payments.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension PodcastPlayerController {
    @objc func updatePlayedTime() {
        playedSeconds = playedSeconds + 1
        
        if playedSeconds > 0 && playedSeconds % PodcastPlayerHelper.kSecondsBeforePMT == 0 {
            DispatchQueue.global().async {
                self.processPayment()
            }
        }
    }
    
    func processPayment(amount: Int? = nil) {
        guard let podcast = podcast, let podcastData = podcastData else {
            return
        }
        
        podcastPaymentsHelper.processPaymentsFor(
            podcastFeed: podcast,
            boostAmount: amount,
            itemId: podcastData.episodeId,
            currentTime: podcastData.currentTime ?? 0
        )
    }
}
