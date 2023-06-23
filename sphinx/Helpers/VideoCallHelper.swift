//
//  VideoCallHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class VideoCallHelper {
    
    public enum CallMode: Int {
        case Audio
        case All
    }
    
    public static func getCallMode(link: String) -> CallMode {
        var mode = CallMode.All
        
        if link.contains("startAudioOnly") {
            mode = CallMode.Audio
        }
        
        return mode
    }
    
    public static func createCallMessage(button: UIButton, callback: @escaping (String) -> ()) {
        let time = Date.timeIntervalSinceReferenceDate
        let room = "\(API.kVideoCallServer)\(TransactionMessage.kCallRoomName).\(time)"
        
        let audioCallback: (() -> ()) = {
            callback(room + "#config.startAudioOnly=true")
        }
        
        let videoCallback: (() -> ()) = {
            callback(room)
        }
        
        AlertHelper.showOptionsPopup(
            title: "create.call".localized,
            message: "select.call.mode".localized,
            options: ["audio".localized, "video.or.audio".localized],
            callbacks: [audioCallback, videoCallback],
            sourceView: button
        )
    }
    
}
