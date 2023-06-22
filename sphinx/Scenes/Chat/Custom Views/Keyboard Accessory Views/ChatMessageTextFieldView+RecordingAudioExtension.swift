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
        
        animatedMicLabelView.toggleAnimation(animate: show)
        
        recordingBlueCircle.isHidden = !show
        recordingContainer.isHidden = !show
    }
    
    func updateRecordingAudio(minutes: String, seconds: String) {
        recordingTimeLabel.text = "\(minutes):\(seconds)"
    }
}
