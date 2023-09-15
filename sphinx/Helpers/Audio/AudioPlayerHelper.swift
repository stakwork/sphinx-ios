//
//  AudioPlayerHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioPlayerHelperDelegate: class {
    func progressCallback(messageId: Int?, rowIndex: Int?, duration: Double, currentTime: Double)
    func pauseCallback(messageId: Int?, rowIndex: Int?)
    func endCallback(messageId: Int?, rowIndex: Int?)
}

class AudioPlayerHelper : NSObject {
    
    weak var delegate: AudioPlayerHelperDelegate?
    
    var playingTimer : Timer? = nil
    var playing = false
    
    var messageId : Int? = nil
    var rowIndex : Int? = nil
    
    let customAudioPlayer = CustomAudioPlayer.sharedInstance
    
    func configureAudioSession() {
        customAudioPlayer.configureAudioSession()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
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
    
    func playAudioFrom(
        data: Data,
        messageId: Int,
        rowIndex: Int,
        atTime: Double? = nil,
        delegate: AudioPlayerHelperDelegate?
    ) {
        self.delegate = delegate
        
        customAudioPlayer.setDelegate(delegate: self)
        customAudioPlayer.toggleProximitySensor(active: true)
        customAudioPlayer.setSessionPlayerOn()
        
        if playing {
            pausePlayingAudio()
        }
        
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateCurrentTime), userInfo: nil, repeats: true)
        
        self.messageId = messageId
        self.rowIndex = rowIndex
        
        let fileURL = getDocumentsDirectory().appendingPathComponent("playing.wav")
        
        do {
            try data.write(to: fileURL)
        } catch {
            return
        }
        
        playing = true
        customAudioPlayer.prepareAudioPlayer(url: fileURL)
        customAudioPlayer.play(atTime: atTime)
    }
    
    func pausePlayingAudio() {
        customAudioPlayer.toggleProximitySensor(active: false)
        stopPlaying()
        
        delegate?.pauseCallback(
            messageId: messageId,
            rowIndex: rowIndex
        )
    }
    
    func stopPlaying() {
        customAudioPlayer.stop()
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    @objc func updateCurrentTime() {
        if let audioPlayerDuration = customAudioPlayer.getDuration(),
            let audioPlayerCurrentTime = customAudioPlayer.getCurrentTime(), audioPlayerDuration > 0 {
            
            if audioPlayerCurrentTime > 0 {
                delegate?.progressCallback(
                    messageId: messageId,
                    rowIndex: rowIndex,
                    duration: audioPlayerDuration,
                    currentTime: audioPlayerCurrentTime
                )
            }
            
        } else {
            audioDidFinishPlaying()
        }
    }
    
    func resetCurrentAudio() {
        playing = false
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    func isPlayingMessageWith(_ messageId: Int) -> Bool {
        return playing && self.messageId == messageId
    }
}

extension AudioPlayerHelper  : CustomAudioPlayerDelegate {
    func audioDidFinishPlaying() {
        resetCurrentAudio()
        customAudioPlayer.toggleProximitySensor(active: false)
        
        delegate?.endCallback(
            messageId: messageId,
            rowIndex: rowIndex
        )
    }
}
