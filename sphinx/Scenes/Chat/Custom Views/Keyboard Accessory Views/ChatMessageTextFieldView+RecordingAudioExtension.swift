//
//  ChatMessageTextFieldView+RecordingAudioExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ChatMessageTextFieldView {    
    func toggleAudioRecording(show: Bool) {
        recordingTimeLabel.text = "0:00"
        recordingBlueCircle.alpha = show ? 1.0 : 0.0
        
        audioButton.titleLabel?.font = UIFont(name: "MaterialIcons-Regular", size: show ? 50 : 27)!
        
        animatedMicLabelView.toggleAnimation(animate: show)
        recordingContainer.alpha = show ? 1.0 : 0.0
    }
    
    func updateRecordingAudio(minutes: String, seconds: String) {
        recordingTimeLabel.text = "\(minutes):\(seconds)"
    }
}
