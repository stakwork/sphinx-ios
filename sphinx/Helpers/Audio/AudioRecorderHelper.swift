//
//  AudioRecorderHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioHelperDelegate: class {
    func didStartRecording(_ success: Bool)
    func didFinishRecording(_ success: Bool)
    func audioTooShort()
    func recordingProgress(minutes: String, seconds: String)
}

class AudioRecorderHelper : NSObject {
    
    weak var delegate: AudioHelperDelegate?
    
    var audioRecorder: AVAudioRecorder!
    var recordingTimer : Timer? = nil
    var proximityTimer : Timer? = nil
    var startRecordingTime = Date()
    
    func configureAudioSession(delegate: AudioHelperDelegate) -> Bool {
        self.delegate = delegate
        
        if AVAudioSession.sharedInstance().recordPermission == .undetermined {
            let recordingSession = AVAudioSession.sharedInstance()
            do {
                try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.interruptSpokenAudioAndMixWithOthers, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
                try recordingSession.setActive(true)
                recordingSession.requestRecordPermission() { allowed in
                    DispatchQueue.main.async {
                        if allowed {
                            print("Microphone permissions granted")
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            return true
        }
        return false
    }
    
    func setSessionPlayerOn() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.interruptSpokenAudioAndMixWithOthers, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
        } catch _ {}
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
    }
    
    func shouldStartRecording() {
        startRecording()
    }
    
    func shouldFinishRecording() {
        finishRecording(success: true)
    }
    
    func shouldCancelRecording() {
        finishRecording(success: false)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getAudioData() -> Data? {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        return MediaLoader.getDataFromUrl(videoURL: audioFilename)
    }
    
    func startRecording() {
        if AVAudioSession.sharedInstance().recordPermission != .granted {
            recordingDidFail()
            return
        }
        
        setSessionPlayerOn()
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
            try FileManager.default.removeItem(at: audioFilename)
        } catch let error {
            print(error)
        }

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            startRecordingTime = Date()
            recordingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateRecordingTime), userInfo: nil, repeats: true)
            
            delegate?.didStartRecording(true)
        } catch {
            recordingDidFail()
        }
    }
    
    func recordingDidFail() {
        audioRecorder?.stop()
        audioRecorder = nil
        delegate?.didStartRecording(false)
    }
    
    func finishRecording(success: Bool) {
        if let _ = audioRecorder {
            audioRecorder?.stop()
            audioRecorder = nil
            
            recordingTimer?.invalidate()
            recordingTimer = nil
            
            if Date().timeIntervalSince(startRecordingTime) > 1 {
                PlayAudioHelper.playHaptic()
                delegate?.didFinishRecording(success)
            } else {
                delegate?.audioTooShort()
            }
        }
    }
    
    @objc func updateRecordingTime() {
        let timeInterval = Date().timeIntervalSince(startRecordingTime)
        let minutes: Int = Int(timeInterval) / 60
        let seconds: Int = Int(timeInterval) % 60
        delegate?.recordingProgress(minutes: "\(minutes)", seconds: seconds.timeString)
    }
}

extension AudioRecorderHelper : AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
