//
//  PodcastPlayerController+InfoCenter.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

//import Foundation
//import AVKit
import MediaPlayer

extension PodcastPlayerController {
    
    func loadEpisodeImage() {
        self.playingEpisodeImage = nil
        
        if let urlString = podcast?.getCurrentEpisode()?.imageURLPath, let url = URL(string: urlString) {
            MediaLoader.loadDataFrom(
                URL: url,
                includeToken: false,
                completion: { (data, fileName) in
                    
                    if let img = UIImage(data: data) {
                        self.playingEpisodeImage = img
                    }
                }, errorCompletion: {
                    self.playingEpisodeImage = nil
                }
            )
        }
    }

    func configurePlayingInfoCenter() {
        guard let podcast = podcast, let episode = podcast.getCurrentEpisode(), podcast.duration > 0 else {
            return
        }
        
        let episodeIndex = podcast.getIndexForEpisodeWith(id: episode.itemID) ?? 0

        let size = playingEpisodeImage?.size ?? CGSize.zero
        let artwork = MPMediaItemArtwork.init(boundsSize: size, requestHandler: { (size) -> UIImage in
            return self.playingEpisodeImage ?? UIImage()
        })
        
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? MPNowPlayingPlaybackState.playing : MPNowPlayingPlaybackState.paused

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyMediaType: "\(MPMediaType.podcast)",
            MPMediaItemPropertyPodcastTitle: podcast.title ?? "",
            MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyPodcastPersistentID: podcast.feedID,
            MPMediaItemPropertyTitle: episode.title ?? "",
            MPMediaItemPropertyArtist: podcast.author ?? "",
            MPMediaItemPropertyPlaybackDuration: "\(podcast.duration)",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: "\(podcast.currentTime)",
            MPNowPlayingInfoPropertyPlaybackRate: podcast.playerSpeed,
            MPMediaItemPropertyAlbumTrackCount: "\(podcast.episodesArray.count)",
            MPMediaItemPropertyAlbumTrackNumber: "\(episodeIndex)",
            MPMediaItemPropertyAssetURL: episode.urlPath ?? ""
        ]
    }
    
    func setupNowPlayingInfoCenter() {
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: kSkipBackSeconds)]
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: kSkipForwardSeconds)]
        
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent
            {
                let positionTime = changePlaybackPositionCommandEvent.positionTime

                self.podcastData?.currentTime = Int(positionTime)
                self.podcast?.currentTime = Int(positionTime)

                if let podcastData = self.podcastData {
                    self.seek(podcastData)
                }

                return .success
            } else {
                return .commandFailed
            }
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            self.shouldPlay()
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.shouldPause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget {event in
            self.shouldSkip15Back()
            return .success
        }
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget {event in
            self.shouldSkip30Forward()
            return .success
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func shouldSkip15Back() {
        let newTime = (self.podcastData?.currentTime ?? 0) - kSkipBackSeconds
        self.podcastData?.currentTime = newTime
        self.podcast?.currentTime = newTime

        if let podcastData = self.podcastData {
            self.seek(podcastData)
        }
    }
    
    func shouldSkip30Forward() {
        let newTime = (self.podcastData?.currentTime ?? 0) + kSkipForwardSeconds
        self.podcastData?.currentTime = newTime
        self.podcast?.currentTime = newTime

        if let podcastData = self.podcastData {
            self.seek(podcastData)
        }
    }
    
    func shouldPlay() {
        if isPlaying {
            return
        }
        
        if let podcastData = self.podcastData {
            self.play(podcastData)
        }
    }
    
    func shouldPause() {
        if !isPlaying {
            return
        }
        
        if let podcastData = self.podcastData {
            self.pause(podcastData)
        }
    }
}
