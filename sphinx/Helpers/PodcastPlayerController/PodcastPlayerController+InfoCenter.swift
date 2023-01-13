//
//  PodcastPlayerController+InfoCenter.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/01/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
//import AVKit
import MediaPlayer

extension PodcastPlayerController {

    func configurePlayingInfoCenterWith(
        _ podcastData: PodcastData
    ) {
        let playingCenter = MPNowPlayingInfoCenter.default()
        
//        let size = self.playingEpisodeImage?.size ?? CGSize.zero
//        let artwork = MPMediaItemArtwork.init(boundsSize: size, requestHandler: { (size) -> UIImage in
//            return self.playingEpisodeImage ?? UIImage()
//        })
//
//        playingCenter.nowPlayingInfo = [
//            MPMediaItemPropertyMediaType: "\(MPMediaType.podcast)",
//            MPMediaItemPropertyPodcastTitle: podcast.title ?? "",
//            MPMediaItemPropertyArtwork: artwork,
//            MPMediaItemPropertyPodcastPersistentID: podcast.id,
//            MPMediaItemPropertyTitle: episode.title ?? "",
//            MPMediaItemPropertyArtist: podcast.author ?? "",
//            MPMediaItemPropertyPlaybackDuration: "\(duration)",
//            MPNowPlayingInfoPropertyElapsedPlaybackTime: "\(currentTime)",
//            MPNowPlayingInfoPropertyPlaybackRate: podcast.playerSpeed,
//            MPMediaItemPropertyAlbumTrackCount: "\(podcast.episodesArray.count)",
//            MPMediaItemPropertyAlbumTrackNumber: "\(podcast.currentEpisodeIndex)",
//            MPMediaItemPropertyAssetURL: episode.urlPath ?? ""
//        ]
    }
    
    func resetPlayingInfoCenter() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func setupNowPlayingInfoCenter() {
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().skipBackwardCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().skipForwardCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = true
        
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent
            {
                let positionTime = changePlaybackPositionCommandEvent.positionTime
                //Call Seek to
                return .success
            } else {
                return .commandFailed
            }
        }
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [15]
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [30]
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            //Play
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            //Pause
            return .success
        }
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget {event in
            //Skip -15 sec
            return .success
        }
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget {event in
            //Skip 30 sec
            return .success
        }
    }
}
