//
//  AudioPlayerHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

class AudioPlayerHelper : NSObject {
    
    var currentTime : TimeInterval = 0
    var playingTimer : Timer? = nil
    var playing = false
    
    var progressCallback: (Double, Double) -> Void = { (_, _) in }
    var endCallback: () -> Void = {}
    var pauseCallback: () -> Void = {}
    
    var messageId : Int? = nil
    
    let customAudioPlayer = CustomAudioPlayer.sharedInstance
    
    func configureAudioSession() {
        customAudioPlayer.configureAudioSession()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func setInitialTime(messageId: Int, data: Data, startTimePercentage: Double) {
        let duration = getAudioDuration(data:data) ?? 0
        let startTime = duration / 100 * startTimePercentage
        currentTime = startTime
    }
    
    func getAudioDuration(data: Data) -> Double? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("audio_length.wav")
        
        do {
            try data.write(to: fileURL)
        } catch {
            return 0.0
        }
        
        var lengthAudioPlayer : AVAudioPlayer?
        do  {
            lengthAudioPlayer = try AVAudioPlayer(contentsOf: fileURL)
        } catch {
            lengthAudioPlayer = nil
        }
        
        return lengthAudioPlayer?.duration
    }
    
    func playAudioFrom(data: Data, messageId: Int,
                       progressCallback: @escaping (Double, Double) -> (),
                       endCallback: @escaping () -> (),
                       pauseCallback: @escaping () -> ()) {
        
        customAudioPlayer.setDelegate(delegate: self)
        customAudioPlayer.toggleProximitySensor(active: true)
        customAudioPlayer.setSessionPlayerOn()
        
        if playing {
            pausePlayingAudio()
            return
        }
        
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
        
        self.messageId = messageId
        self.progressCallback = progressCallback
        self.endCallback = endCallback
        self.pauseCallback = pauseCallback
        
        let fileURL = getDocumentsDirectory().appendingPathComponent("playing.wav")
        
        do {
            try data.write(to: fileURL)
        } catch {
            return
        }
        
        playing = true
        customAudioPlayer.prepareAudioPlayer(url: fileURL)
        setResumingTime()
        customAudioPlayer.play()
    }
    
    func pausePlayingAudio() {
        customAudioPlayer.toggleProximitySensor(active: false)
        stopPlaying()
        pauseCallback()
    }
    
    func stopPlaying() {
        customAudioPlayer.stop()
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    func setResumingTime() {
        if currentTime > 0 {
            customAudioPlayer.setCurrentTime(currentTime: currentTime)
        }
    }
    
    @objc func updateCurrentTime() {
        if let audioPlayerDuration = customAudioPlayer.getDuration(), let audioPlayerCurrentTime = customAudioPlayer.getCurrentTime(), audioPlayerDuration > 0 {
            currentTime = audioPlayerCurrentTime
            
            if audioPlayerCurrentTime > 0 {
                progressCallback(audioPlayerDuration, audioPlayerCurrentTime)
            }
        } else {
            audioDidFinishPlaying()
        }
    }
    
    func resetCurrentAudio() {
        playing = false
        currentTime = 0
        playingTimer?.invalidate()
        playingTimer = nil
    }
}

extension AudioPlayerHelper  : CustomAudioPlayerDelegate {
    func audioDidFinishPlaying() {
        resetCurrentAudio()
        customAudioPlayer.toggleProximitySensor(active: false)
        endCallback()
    }
}
