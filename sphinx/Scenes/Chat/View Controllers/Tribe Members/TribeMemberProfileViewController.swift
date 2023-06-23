//
//  TribeMemberProfileViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/11/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class TribeMemberProfileViewController: UIViewController {
    
    weak var delegate: TribeMemberViewDelegate!
    
    var message: TransactionMessage!

    @IBOutlet weak var tribeMemberProfileContainer: UIView!
    @IBOutlet weak var tribeMemberProfileView: TribeMemberProfileView!
    @IBOutlet weak var tribeMemberProfileViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingViewContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var loading = false {
        didSet {
            loadingViewContainer.alpha = loading ? 1.0 : 0.0
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white)
        }
    }
    
    static func instantiate(
        message : TransactionMessage,
        delegate: TribeMemberViewDelegate
    ) -> TribeMemberProfileViewController {
        let viewController = StoryboardScene.Chat.tribeMemberProfileViewController.instantiate()
        viewController.message = message
        viewController.delegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tribeMemberProfileView.delegate = self
        
        runInitialAnimation()
    }

    func runInitialAnimation() {
        let windowInset = getWindowInsets()
        
        self.loading = true
        self.view.alpha = 0.0
        self.view.layoutSubviews()
        
        self.tribeMemberProfileContainer.roundCorners(corners: [.topLeft, .topRight], radius: 15)
        self.tribeMemberProfileViewBottomConstraint.constant = -(loadingViewContainer.frame.height + windowInset.bottom)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.view.alpha = 1.0
        }, completion: { _ in
            
            self.tribeMemberProfileViewBottomConstraint.constant = 0

            UIView.animate(withDuration: 0.3, animations: {
                self.tribeMemberProfileContainer.superview?.layoutSubviews()
            }, completion: { _ in
                self.loadProfileData()
            })
        })
    }
    
    func runDismissAnimation(
        completion: @escaping () -> ()
    ) {
        let windowInset = getWindowInsets()
        self.tribeMemberProfileViewBottomConstraint.constant = -(loadingViewContainer.frame.height + windowInset.bottom)

        UIView.animate(withDuration: 0.3, animations: {
            self.tribeMemberProfileContainer.superview?.layoutSubviews()
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.view.alpha = 0.0
            }, completion: { _ in
                self.dismiss(animated: false)
                completion()
            })
        })
    }
    
    func loadProfileData() {
        guard let person = message.person else {
            dismissView()
            return
        }
        
        API.sharedInstance.getTribeMemberInfo(person: person, callback: { (success, personInfo) in
            if let personInfo = personInfo, success {
                self.tribeMemberProfileView.configureWith(tribeMember: personInfo)
                self.loading = false
            } else {
                self.dismissView()
            }
        })
    }
    
    func dismissView() {
        runDismissAnimation() {
//            self.delegate?.didDismissTribeMemberVC()
        }
    }
}

extension TribeMemberProfileViewController: TribeMemberProfileViewDelegate {
    func didTapSendSats() {
        runDismissAnimation() {
            self.delegate?.shouldGoToSendPayment(message: self.message)
        }
    }
    
    func dismissLineWasDragged(
        gestureRecognizer: UIPanGestureRecognizer,
        view: UIView
    ) {
        let y = gestureRecognizer.translation(in: view).y
        print(y)
        
        switch(gestureRecognizer.state) {
        case .changed:
            if (y > 0) {
                self.tribeMemberProfileViewBottomConstraint.constant = -(y)
                self.tribeMemberProfileContainer.superview?.layoutSubviews()
            }
            break
        case .ended:
            if (y > 50) {
                dismissView()
            } else {
                self.tribeMemberProfileViewBottomConstraint.constant = 0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.tribeMemberProfileContainer.superview?.layoutSubviews()
                })
            }
            break
        default:
            break
        }
    }
}
