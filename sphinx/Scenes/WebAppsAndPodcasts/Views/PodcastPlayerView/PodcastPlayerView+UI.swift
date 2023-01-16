//
//  PodcastPlayerView+UI.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import AVFoundation

extension PodcastPlayerView {
    func showInfo() {
        if let imageURL = podcast?.getImageURL() {
            loadImage(imageURL: imageURL)
        }

        episodeLabel.text = podcast.getCurrentEpisode()?.title ?? ""
        
        loadTime()
        loadMessages()
    }
    
    func loadTime() {
        let episode = podcast.getCurrentEpisode()
        
        if let duration = episode?.duration {
            let _ = setProgress(
                duration: duration,
                currentTime: episode?.currentTime ?? 0
            )
        } else if let url = episode?.getAudioUrl() {
            let asset = AVAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: {
                let duration = Int(Double(asset.duration.value) / Double(asset.duration.timescale))
                episode?.duration = duration
                
                DispatchQueue.main.async {
                    let _ = self.setProgress(
                        duration: duration,
                        currentTime: episode?.currentTime ?? 0
                    )
                }
            })
        }
    }
    
    func loadImage(imageURL: URL?) {
        guard let imageURL = imageURL else {
            self.episodeImageView.image = UIImage(named: "profile_avatar")!
            return
        }
        
        MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: imageURL, placeHolderImage: nil, completion: { img in
            self.episodeImageView.image = img
        }, errorCompletion: { _ in
            self.episodeImageView.image = UIImage(named: "profile_avatar")!
        })
    }
    
    func loadMessages() {
        guard let chat = chat else { return }
        
        if livePodcastDataSource == nil {
            livePodcastDataSource = PodcastLiveDataSource(tableView: liveTableView, chat: chat)
        }
        
        let episodeId = podcast.getCurrentEpisode()?.itemID ?? ""
        
        if (episodeId != livePodcastDataSource?.episodeId) {
            
            livePodcastDataSource?.episodeId = episodeId
            
            let messages = TransactionMessage.getLiveMessagesFor(chat: chat, episodeId: episodeId)
            
            liveMessages = [:]
            
            for m in messages {
                addToLiveMessages(message: m)
            }
            
            livePodcastDataSource?.resetData()
        }
    }
    
    func configureControls(
        playing: Bool? = nil
    ) {
        let isPlaying = playing ?? podcastPlayerController.isPlaying(podcastId: podcast.feedID)
        playPauseButton.setTitle(isPlaying ? "pause" : "play_arrow", for: .normal)
        speedButton.setTitle(podcast.playerSpeed.speedDescription + "x", for: .normal)
    }
    
    func setProgress(
        duration: Int,
        currentTime: Int
    ) -> Bool {
        
        let currentTimeString = currentTime.getPodcastTimeString()
        let didChangeCurrentTime = currentTimeLabel.text != currentTimeString
        
        currentTimeLabel.text = currentTimeString
        durationLabel.text = duration.getPodcastTimeString()
        
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        let durationLineWidth = UIScreen.main.bounds.width - 64
        var progressWidth = durationLineWidth * CGFloat(progress)
        
        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }
        
        progressLineWidth.constant = progressWidth
        progressLine.layoutIfNeeded()
        
        return didChangeCurrentTime
    }
    
    func addMessagesFor(ts: Int) {
        if !podcastPlayerController.isPlaying(podcastId: podcast.feedID) {
            return
        }
        
        if let liveM = liveMessages[ts] {
            livePodcastDataSource?.insert(messages: liveM)
        }
    }
}
