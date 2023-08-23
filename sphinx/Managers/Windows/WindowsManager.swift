//
//  WindowsManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol WindowsManagerDelegate: class {
    func didDismissCoveringWindows()
}

class WindowsManager {

    class var sharedInstance : WindowsManager {
        struct Static {
            static let instance = WindowsManager()
        }
        return Static.instance
    }
    
    weak var delegate : WindowsManagerDelegate?
    
    public static func getWindowSize() -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    public static func getWindowWidth() -> CGFloat {
        WindowsManager.getWindowSize().width
    }
    
    public static func getWindowHeight() -> CGFloat {
        WindowsManager.getWindowSize().height
    }
    
    var coveringWindow : PassthroughWindow?
    
    func getCoveringWindow() -> UIWindow? {
        guard let windowFrame = UIApplication.shared.windows.first?.frame else {
            return nil
        }
        
        if coveringWindow == nil {
            coveringWindow = PassthroughWindow(frame: windowFrame)
        }
        coveringWindow?.windowLevel = UIWindow.Level.alert + 1
        return coveringWindow
    }
    
    func getCoveringWindowWith(rootVC: UIViewController) -> UIWindow? {
        let window = getCoveringWindow()
        window?.rootViewController = rootVC
        window?.setStyle()
        return window
    }
    
    func removeCoveringWindow() {
        coveringWindow?.isHidden = true
        coveringWindow?.resignKey()
        coveringWindow = nil
        delegate?.didDismissCoveringWindows()
    }
    
    func showStakworkAuthorizeWith() -> Bool {
        if let challengeQuery = UserDefaults.Keys.challengeQuery.get(defaultValue: ""), challengeQuery != "" {
            UserDefaults.Keys.challengeQuery.removeValue()
            let authorizeVC = StakworkAuthorizeViewController.instantiate(query: challengeQuery)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: authorizeVC)
            return true
        }
        return false
    }
    
    func showRedeemSats() -> Bool {
        if let redeemSatsQuery = UserDefaults.Keys.redeemSatsQuery.get(defaultValue: ""), redeemSatsQuery != "" {
            UserDefaults.Keys.redeemSatsQuery.removeValue()
            
            let authorizeVC = StakworkAuthorizeViewController.instantiate(query: redeemSatsQuery)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: authorizeVC)
            return true
        }
        return false
    }
    
    func showAuth() -> Bool {
        if let authQuery = UserDefaults.Keys.authQuery.get(defaultValue: ""), authQuery != "" {
            UserDefaults.Keys.authQuery.removeValue()
            
            let peopleModalsVC = PeopleModalsViewController.instantiate(query: authQuery)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: peopleModalsVC)
            return true
        }
        return false
    }
    
    func showPersonModal(delegate: WindowsManagerDelegate? = nil) -> Bool {
        if let personQuery = UserDefaults.Keys.personQuery.get(defaultValue: ""), personQuery != "" {
            UserDefaults.Keys.personQuery.removeValue()
            
            self.delegate = delegate
            
            let peopleModalsVC = PeopleModalsViewController.instantiate(query: personQuery)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: peopleModalsVC)
            return true
        }
        return false
    }
    
    func showPeopleUpdateModal(delegate: WindowsManagerDelegate? = nil) -> Bool {
        if let saveQuery = UserDefaults.Keys.saveQuery.get(defaultValue: ""), saveQuery != "" {
            UserDefaults.Keys.saveQuery.removeValue()
            
            self.delegate = delegate
            
            let peopleModalsVC = PeopleModalsViewController.instantiate(query: saveQuery)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: peopleModalsVC)
            return true
        }
        return false
    }
    
    func showConveringWindowWith(rootVC: UIViewController) {
        if let rootVController = rootVC as? RootViewController, let currentVC = rootVController.getLastCenterViewController() {
            currentVC.view.endEditing(true)
        }
        
        let coveringWindow = getCoveringWindowWith(rootVC: rootVC)
        coveringWindow?.isHidden = false
    }
    
    func shouldRotateOrientation() -> Bool {
        if let coveringWindow = coveringWindow, let rootVC = coveringWindow.rootViewController {
            return rootVC is CanRotate
        }
        return false
    }
}

class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
