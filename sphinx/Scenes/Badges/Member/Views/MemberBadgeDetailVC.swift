//
//  MemberBadgeDetailVC.swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


public enum MemberBadgeDetailPresentationContext {
    case member
    case admin
}

class MemberBadgeDetailVC : UIViewController{
    
    @IBOutlet weak var detailViewHeight: NSLayoutConstraint!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var detailBackView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var panGestureLine: UIView!
    @IBOutlet weak var panGestureView: UIView!
    
    @IBOutlet weak var detailViewBottomConstraint: NSLayoutConstraint!
    private lazy var loadingViewController = LoadingViewController(backgroundColor: UIColor.clear)
    
    var presentationContext : MemberBadgeDetailPresentationContext = .admin
    var delegate : TribeMemberViewDelegate? = nil
    var loadingView: UIView? = nil
    var chatID: Int? = nil

    var memberBadgeDetailVM : MemberBadgeDetailVM!
    
    static func instantiate(
        delegate: TribeMemberViewDelegate
    ) -> MemberBadgeDetailVC {
        
        let viewController = StoryboardScene.BadgeManagement.memberBadgeDetailVC.instantiate() as! MemberBadgeDetailVC
        viewController.delegate = delegate
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        memberBadgeDetailVM.tableView = tableView
        
        configureBadgeDetails()
        setupDismissableView()
        configTableView()
        
        addSemiTransparentBack()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateView(show: true)
    }
    
    func handleEarnBadgesTap() {
        self.dismiss(animated: true, completion: {
            self.delegate?.shouldDisplayKnownBadges()
        })
    }
    
    func handleSatsButtonSend(){
        if let valid_message = memberBadgeDetailVM.message {
            self.dismiss(animated: false,completion: {
                self.delegate?.shouldGoToSendPayment(message: valid_message)
            })
        }
    }
    
    func addSemiTransparentBack(){
        let backView = UIView(frame: self.view.frame)
        backView.backgroundColor = .black
        backView.alpha = 0.75
        self.view.addSubview(backView)
        self.view.sendSubviewToBack(backView)
    }
    
    func addShimmerLoadingView(){
        if let loadingView = loadingView {
            tableView.isHidden = true
            loadingView.isHidden = false
            return
        }
        
        let loadingViewFrame = CGRect(
            x: 32.0,
            y: 10.0,
            width: detailView.bounds.width - 64.0,
            height: detailView.bounds.height - 10.0
        )
        
        loadingView = UIView(frame: loadingViewFrame)
        loadingView?.isUserInteractionEnabled = false
        loadingView?.backgroundColor = UIColor.clear
        
        if let loadingView = loadingView {
            
            let imageView : UIImageView = UIImageView(frame: loadingView.bounds)
            imageView.image = UIImage(named: "memberBadgeLoadingView")
            imageView.contentMode = .scaleAspectFit
            imageView.alpha = 1.0
            
            loadingView.addSubview(imageView)
            detailView.addSubview(loadingView)
            detailView.bringSubviewToFront(loadingView)
            
            tableView.isHidden = true
        }
    }
    
    func removeShimmerView(){
        tableView.isHidden = false
        loadingView?.removeFromSuperview()
    }
    
    func configTableView(){
        memberBadgeDetailVM.configTable()
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
    }
    
    func configureBadgeDetails() {
        detailBackView.layer.cornerRadius = 20.0
        detailViewHeight.constant = (memberBadgeDetailVM.badges.count > 0) ? 478.0 : 430.0
        detailView.superview?.layoutSubviews()
    }
    
    func dismissBadgeDetails(){
        tableView.isScrollEnabled = false
        detailViewHeight.constant = (memberBadgeDetailVM.badges.count > 0) ? 478.0 : 430.0
        
        UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
            self.detailView.superview?.layoutSubviews()
        })
    }
    
    func expandBadgeDetail(){
        tableView.isScrollEnabled = true
        detailViewHeight.constant = self.view.frame.height * 0.9
        
        UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
            self.detailView.superview?.layoutSubviews()
        })
    }
    
    
    func setupDismissableView() {
        panGestureLine.makeCircular()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        panGestureView.addGestureRecognizer(panGesture)
    }
    
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view).y

        guard translation >= 0 else { return }
        
        if sender.state == .began {
            detailViewBottomConstraint.constant = 0
            detailView.superview?.layoutSubviews()
            return
        }
        
        if sender.state == .changed {
            detailViewBottomConstraint.constant = -translation
            detailView.superview?.layoutSubviews()
            return
        }

        if sender.state == .ended {
            if translation > 200 {
                animateView(show: false) {
                    self.dismiss(animated: false)
                }
            } else {
                animateView(show: true)
            }
        }
    }
    
    func dismissView() {
        animateView(show: false) {
            self.dismiss(animated: false)
        }
    }
    
    func animateView(
        show: Bool,
        completion: (() -> ())? = nil
    ) {
        let windowInset = getWindowInsets()
        let newConstant: CGFloat = show ? 0 : -(detailViewHeight.constant + windowInset.bottom)
        
        if (detailViewBottomConstraint.constant == newConstant) {
            return
        }
        
        self.detailViewBottomConstraint.constant = newConstant
        
        UIView.animate(withDuration: 0.25, animations: {
            self.detailView.superview?.layoutSubviews()
        }) { _ in
            completion?()
        }
    }
    
}
