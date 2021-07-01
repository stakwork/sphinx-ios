//
//  AVAudioSession.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import AVFoundation

extension AVAudioSession {

    static var isDeviceConnected: Bool {
        return sharedInstance().isDeviceConnected
    }

    var isDeviceConnected: Bool {
        return !currentRoute.outputs.filter { $0.isDeviceConnected }.isEmpty
    }
}

extension AVAudioSessionPortDescription {
    var isDeviceConnected: Bool {
        return (portType == .airPlay || portType == .bluetoothA2DP || portType == .bluetoothLE || portType == .bluetoothHFP || portType == .carAudio || portType == .headphones || portType == .headsetMic || portType == .usbAudio)
    }
}
