//
//  SetPinCodeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation

class SetPinCodeViewController: UIViewController {

    private var rootViewController : RootViewController!
    
    @IBOutlet var dotViews: [UIView]!
    @IBOutlet var keyPadButtons: [UIButton]!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var pinArray = [Int]()
    var pin = ""
    var subtitle = ""
    
    let kDeleteButtonTag = 10
    let kResetButtonTag = 11
    
    let kFirstTitle = "choose.pin.upper".localized
    let kSecondTitle = "confirm.pin.upper".localized
    
    let kOldPinTitle = "enter.old.pin".localized
    let kNewPinTitle = "enter.new.pin".localized
    
    public enum SetPinMode: Int {
        case Set
        case Change
    }
    
    public enum PinMode: Int {
        case Standard
        case Privacy
    }
    
    var mode = SetPinMode.Set
    var pinMode = PinMode.Standard
    
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var doneCompletion: ((String) -> ())? = nil
    
    static func instantiate(rootViewController : RootViewController? = nil, mode: SetPinMode = SetPinMode.Set, pinMode: PinMode = PinMode.Standard, subtitle: String = "") -> SetPinCodeViewController {
        let viewController = StoryboardScene.Pin.setPinCodeViewController.instantiate()
        viewController.rootViewController = rootViewController
        viewController.mode = mode
        viewController.pinMode = pinMode
        viewController.subtitle = subtitle
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loading = false
        subtitleLabel.text = subtitle
        reloadDots()
        configureButtons()
        
        titleLabel.text = (mode == SetPinMode.Set) ? kFirstTitle : kOldPinTitle
    }
    
    func configureButtons() {
        for button in keyPadButtons {
            button.setTitleColor(UIColor.Sphinx.HeaderBG.withAlphaComponent(0.5), for: .highlighted)
        }
    }
    
    func reloadDots() {
        for dot in dotViews {
            dot.layer.cornerRadius = dot.frame.height/2
            dot.layer.borderColor = UIColor.white.cgColor
            dot.layer.borderWidth = 1
            dot.clipsToBounds = true
            
            dot.backgroundColor = dot.tag < pinArray.count ? UIColor.white : UIColor.clear
        }
    }
    
    @IBAction func pinButtonTouched(_ sender: UIButton) {
        if sender.tag == kResetButtonTag {
            pin = ""
            pinArray = []
            reloadDots()
            titleLabel.text = (mode == SetPinMode.Set) ? kFirstTitle : kOldPinTitle
            return
        }
        
        if sender.tag == kDeleteButtonTag {
            if pinArray.count > 0 {
                PlayAudioHelper.playKeySound(soundId: PlayAudioHelper.deleteSoundID)
                pinArray.removeLast()
            }
        } else {
            if pinArray.count < 6 {
                PlayAudioHelper.playKeySound(soundId: PlayAudioHelper.keySoundID)
                pinArray.append(sender.tag)
            }
        }
        reloadDots()
        
        if pinArray.count >= 6 {
            loading = true
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
                self.didEnterPin()
            }
        }
    }
    
    func didEnterPin() {
        if (mode == SetPinMode.Set) {
            didEnterPinForSet()
        } else {
            didEnterPinForChange()
        }
    }
    
    func didEnterPinForSet() {
        loading = false
        
        if pin == "" {
            pin = getPinString()
            pinArray = []
            reloadDots()
            titleLabel.text = kSecondTitle
        } else {
            if pin == getPinString() {
                doneButtonTouched()
            } else {
                pinArray = []
                reloadDots()
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "pin.doesnt.match".localized)
            }
        }
    }
    
    func didEnterPinForChange() {
        loading = false
        
        if pin == "" {
            pin = getPinString()
            pinArray = []
            reloadDots()
            
            if pin == getOldPin() {
                titleLabel.text = kNewPinTitle
            } else {
                pin = ""
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "pin.doesnt.match".localized)
            }
        } else {
            doneButtonTouched()
        }
    }
    
    func getOldPin() -> String? {
        if (pinMode == PinMode.Standard) {
            return UserData.sharedInstance.getAppPin()
        } else {
            return UserData.sharedInstance.getPrivacyPin()
        }
    }
    
    func getPinString() -> String {
        var pin = ""
        for number in pinArray {
            pin = "\(pin)\(number)"
        }
        return pin
    }
    
    func setPinArray(pin: String) {
        pinArray = pin.compactMap{ $0.wholeNumberValue }
    }
    
    func doneButtonTouched() {
        if let doneCompletion = doneCompletion {
            doneCompletion(getPinString())
        } else {
            UserData.sharedInstance.save(pin: getPinString())
            
            SignupHelper.step = SignupHelper.SignupStep.PINSet.rawValue
            let nicknameVC = SetNickNameViewController.instantiate(rootViewController: rootViewController)
            self.navigationController?.pushViewController(nicknameVC, animated: true)
        }
    }
}
