//
//  VideoCallManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 09/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import JitsiMeetSDK

class VideoCallManager : NSObject {

    class var sharedInstance : VideoCallManager {
        struct Static {
            static let instance = VideoCallManager()
        }
        return Static.instance
    }

    var pipViewCoordinator: CustomPipViewCoordinator?
    var jitsiMeetView: JitsiMeetView?
    var videoCallPayButton: VideoCallPayButton?

    var chat: Chat? = nil
    var videoCallDelegate: VideoCallDelegate? = nil

    var onPiP = false
    var activeCall = false

    func configure(chat: Chat? = nil, videoCallDelegate: VideoCallDelegate) {
        self.chat = chat
        self.videoCallDelegate = videoCallDelegate
    }

    func isGroupChat() -> Bool {
        let isGroup = (chat?.isGroup() ?? false)
        return isGroup
    }

    func startVideoCall(link: String, audioOnly: Bool) {
        if activeCall {
            return
        }

        if let owner = UserContact.getOwner() {
            cleanUp()

            let jitsiMeetView = JitsiMeetView()
            jitsiMeetView.delegate = self
            self.jitsiMeetView = jitsiMeetView

            let options = JitsiMeetConferenceOptions.fromBuilder({(builder: JitsiMeetConferenceOptionsBuilder) -> Void in
                builder.serverURL = URL(string: link.callServer)!
                builder.room = link.callRoom
                builder.audioOnly = audioOnly
                builder.audioMuted = false
                builder.videoMuted = false
                builder.welcomePageEnabled = false
                builder.subject = " "
                builder.userInfo = JitsiMeetUserInfo(
                    displayName: owner.nickname,
                    andEmail: nil,
                    andAvatar: URL(string: owner.avatarUrl ?? "")
                )
            })

            jitsiMeetView.join(options)
            jitsiMeetView.alpha = 0
            jitsiMeetView.layer.cornerRadius = 10
            jitsiMeetView.clipsToBounds = true

            if let window = UIApplication.shared.windows.first {
                pipViewCoordinator = CustomPipViewCoordinator(withView: jitsiMeetView)
                pipViewCoordinator?.delegate = self
                pipViewCoordinator?.configureAsStickyView(withParentView: window)
                pipViewCoordinator?.initialPositionInSuperview = .upperRightCorner
                pipViewCoordinator?.show()

                if !isGroupChat() {
                    videoCallPayButton = getPaymentView()
                    window.addSubview(videoCallPayButton!)
                }
            }
        }
    }

    func getPaymentView() -> VideoCallPayButton {
        let windowWidth = WindowsManager.getWindowWidth()
        let videoCallPayButton = VideoCallPayButton(frame: CGRect(x: windowWidth/2, y: getWindowInsets().top + 15, width: windowWidth/2, height: 46.0))
        videoCallPayButton.configure(delegata: self.videoCallDelegate, amount: UserContact.kTipAmount)
        videoCallPayButton.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        videoCallPayButton.isHidden = true
        return videoCallPayButton
    }

    fileprivate func cleanUp() {
        onPiP = false
        activeCall = false

        videoCallPayButton?.removeFromSuperview()
        videoCallPayButton = nil

        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil

        pipViewCoordinator = nil
    }

    func paymentSent() {
        PlayAudioHelper.playKeySound(soundId: PlayAudioHelper.PaymentSent)
        videoCallPayButton?.animatePayment()
    }

    func activeFullScreenCall() -> Bool {
        return activeCall && !onPiP
    }
}

extension VideoCallManager : JitsiMeetViewDelegate {
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        activeCall = true

        if onPiP {
            return
        }

        videoCallPayButton?.isHidden = isGroupChat()
    }

    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.videoCallPayButton?.isHidden = true

            self.pipViewCoordinator?.hide() { _ in
                self.cleanUp()
            }
            
            self.videoCallDelegate?.didFinishCall()
        }
    }

    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }
}

extension VideoCallManager : CustomPipViewCoordinatorDelegate {
    func enterPictureInPicture() {
        onPiP = true
        videoCallPayButton?.isHidden = true
        videoCallDelegate?.didSwitchMode(pip: true)
    }

    func exitPictureInPicture() {
        onPiP = false
        videoCallDelegate?.didSwitchMode(pip: false)
        hideKeyboardOnCurrentVC()

        DelayPerformedHelper.performAfterDelay(seconds: 0.25, completion: {
            self.videoCallPayButton?.isHidden = self.isGroupChat()
        })
    }

    func hideKeyboardOnCurrentVC() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let centerVC = appDelegate.getCurrentVC()
        centerVC?.view.endEditing(true)
    }
}
