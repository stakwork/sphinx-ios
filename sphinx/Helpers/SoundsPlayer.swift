//
//  SoundsPlayer.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

class SoundsPlayer {
    
    static let PaymentSent: SystemSoundID = 1008
    static let keySoundID: SystemSoundID = 1123
    static let deleteSoundID: SystemSoundID = 1155
    static let VibrateSoundID: SystemSoundID = 4095
    static let MessageReceivedSoundID: SystemSoundID = 1002
    
    public static func playKeySound(soundId: SystemSoundID) {
        AudioServicesPlaySystemSound(soundId)
    }
    
    var player : AVAudioPlayer? = nil
    
    func playSound(name: String) {
        let components = name.components(separatedBy: ".")
        
        if components.count < 2 {
            return
        }
        
        guard let fileExtension = components.last else {
            return
        }
        
        var fileName = name.replacingOccurrences(of: fileExtension, with: "")
        fileName.removeLast()
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)

                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()

            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    public static func playHaptic() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    
    public static func playReceivedMessageSound(chat: Chat?) {
        if let chat = chat, chat.isMuted() {
            return
        }
        
        AudioServicesPlaySystemSound(SoundsPlayer.MessageReceivedSoundID)
    }
}
