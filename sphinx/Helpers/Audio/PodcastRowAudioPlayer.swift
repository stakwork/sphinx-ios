//
//  PodcastRowAudioPlayer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVKit

class PodcastRowAudioPlayer : NSObject {

    class var sharedInstance : PodcastRowAudioPlayer {
        struct Static {
            static let instance = PodcastRowAudioPlayer()
        }
        return Static.instance
    }
    
    var audioPlayer: AVPlayer?
    
    func prepareAudioPlayer(item: AVPlayerItem) {
        if audioPlayer == nil {
            audioPlayer = AVPlayer(playerItem: item)
            audioPlayer!.rate = 1.0
        } else {
            audioPlayer!.replaceCurrentItem(with: item)
        }
    }
    
    func play() {
        audioPlayer?.play()
    }
    
    func stop() {
        audioPlayer?.pause()
    }
    
    func stopAndReset() {
        stop()
        audioPlayer = nil
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.timeControlStatus == AVPlayer.TimeControlStatus.playing || audioPlayer?.timeControlStatus == AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate
    }
    
    func getCurrentTime() -> Int? {
        guard let player = audioPlayer else {
            return nil
        }
        
        let currentTime = Double(player.currentTime().value) / Double(player.currentTime().timescale)
        return Int(currentTime)
    }
    
    func setCurrentTime(currentTime: Int) {
        guard let player = audioPlayer else {
            return
        }
        
        player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1))
    }
    
    func getDuration() -> Double? {
        guard let player = audioPlayer, let item = player.currentItem else {
            return nil
        }
        
        let duration = Double(item.asset.duration.value) / Double(item.asset.duration.timescale)
        return duration
    }
}
