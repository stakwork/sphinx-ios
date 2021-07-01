//
//  AudioPlayer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit
import AVFoundation

protocol CustomAudioPlayerDelegate: class {
    func audioDidFinishPlaying()
}

class CustomAudioPlayer : NSObject {
    
    weak var delegate: CustomAudioPlayerDelegate?

    class var sharedInstance : CustomAudioPlayer {
        struct Static {
            static let instance = CustomAudioPlayer()
        }
        return Static.instance
    }
    
    var proximityTimer : Timer? = nil
    
    var audioPlayer: AVAudioPlayer?
    
    func setDelegate(delegate: CustomAudioPlayerDelegate?) {
        self.delegate = delegate
    }
    
    func configureAudioSession() {
        let playingSession = AVAudioSession.sharedInstance()
        do {
            try playingSession.setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers])
            try playingSession.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func setSessionPlayerOn() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers])
        } catch _ {}
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
        
        switchOutputAudioPort()
    }
    
    @objc func proximityChanged() {
        switchOutputAudioPort()
    }

    func toggleProximitySensor(active: Bool) {
        if active {
            UIDevice.current.isProximityMonitoringEnabled = true
            proximityTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(proximityChanged), userInfo: nil, repeats: true)
        } else {
            UIDevice.current.isProximityMonitoringEnabled = false
            proximityTimer?.invalidate()
            proximityTimer = nil
        }
    }
    
    func switchOutputAudioPort() {
        let phoneOnEar = UIDevice.current.proximityState
        
        let deviceConnected = AVAudioSession.isDeviceConnected
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(phoneOnEar || deviceConnected ? .none : .speaker)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func prepareAudioPlayer(url: URL) {
        do  {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
        } catch {
            audioPlayer = nil
        }
    }
    
    func play() {
        audioPlayer?.play()
    }
    
    func stop() {
        audioPlayer?.stop()
    }
    
    func stopAndReset() {
        stop()
        audioPlayer = nil
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    func getCurrentTime() -> TimeInterval? {
        return audioPlayer?.currentTime
    }
    
    func setCurrentTime(currentTime: Double) {
        audioPlayer?.currentTime = currentTime
    }
    
    func getDuration() -> TimeInterval? {
        return audioPlayer?.duration
    }
}

extension CustomAudioPlayer  : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            delegate?.audioDidFinishPlaying()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {}

    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {}

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        player.play()
    }
}
