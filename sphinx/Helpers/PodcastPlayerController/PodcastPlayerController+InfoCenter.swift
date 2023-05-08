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
            if let image = self.playingEpisodeImage{
                return image
            }
            else if let url = URL(string: episode.feed?.imageURLPath ?? "") {
                let session = URLSession.shared
                let task = session.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        print("Error downloading image: \(error)")
                        return
                    }
                    
                    if let data = data,
                        let image = UIImage(data: data) {
                        // Do something with the image, such as displaying it in an image view
                        // Note: This closure is executed on a background thread, so you need to dispatch UI updates to the main thread
                        DispatchQueue.main.async {
                            self.playingEpisodeImage = image
                            self.configurePlayingInfoCenter()
                        }
                    }
                }
                task.resume()
            }
            return #imageLiteral(resourceName: "appPinIcon")
        })
        
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? MPNowPlayingPlaybackState.playing : MPNowPlayingPlaybackState.paused
        /*
        if episode.urlPath == "https://megaphone.imgix.net/podcasts/e4c412e6-e1f0-11e8-9bde-83f9d376f059/image/Podcast_Tile_6000x6000px.png?ixlib=rails-4.3.1&max-w=3000&max-h=3000&fit=crop&auto=format,compress"{
            episode.urlPath = "https://megaphone.imgix.net/podcasts/e4c412e6-e1f0-11e8-9bde-83f9d376f059/image/Podcast_Tile_6000x6000px.png"
        }
        */
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
    
    func resetPlayingInfoCenter() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
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
