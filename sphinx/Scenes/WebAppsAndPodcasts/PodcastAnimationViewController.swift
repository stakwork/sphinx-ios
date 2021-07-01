//
//  PodcastAnimationViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PodcastAnimationViewController: UIViewController {
    
    var amount: Int = 0
    
    static func instantiate(amount: Int) -> PodcastAnimationViewController {
        let viewController = StoryboardScene.WebApps.podcastAnimationViewController.instantiate()
        viewController.amount = amount
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.alpha = 0.0
    }
    
    func showBoostAnimation() {
        let screenSize = UIScreen.main.bounds
        let frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        let animationView = BoostFireworksAnimationView(frame: frame)
        let success = animationView.configureWith(amount: amount, delegate: self)
        
        if success {
            self.view.addSubview(animationView)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 1.0
            })
        } else {
            WindowsManager.sharedInstance.removeCoveringWindow()
        }
    }
    
    func hideAfterTime(delay: Double = 0) {
        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 0.0
            }, completion: { _ in
                WindowsManager.sharedInstance.removeCoveringWindow()
            })
        })
    }
}

extension PodcastAnimationViewController : AnimationViewDelegate {
    func animationDidFinish() {
        hideAfterTime()
    }
}
