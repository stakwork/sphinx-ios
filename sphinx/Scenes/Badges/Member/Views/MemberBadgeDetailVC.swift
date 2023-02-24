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
    var message : TransactionMessage? = nil
    var loadingView: UIView? = nil
    var isModerator : Bool = false
    var chatID: Int? = nil
    var knownTribeBadges : [Badge] = []

    lazy var memberBadgeDetailVM : MemberBadgeDetailVM = {
       return MemberBadgeDetailVM(vc: self, tableView: tableView)
    }()
    
    static func instantiate(
        message: TransactionMessage,
        leaderboardEntry: ChatLeaderboardEntry,
        delegate: TribeMemberViewDelegate,
        knownTribeBadges:[Badge]
    ) -> UIViewController {
        
        let viewController = StoryboardScene.BadgeManagement.memberBadgeDetailVC.instantiate()
        viewController.view.backgroundColor = .clear
        
        if let vc = viewController as? MemberBadgeDetailVC{
            vc.memberBadgeDetailVM.leaderBoardData = leaderboardEntry
            vc.message = message
            vc.delegate = delegate
            vc.knownTribeBadges = knownTribeBadges
            vc.isModerator = message.senderAlias == message.chat?.ownerPubkey
            vc.chatID = message.chat?.id
        }
        
        return viewController
    }
    
    override func viewDidLoad() {
        configureBadgeDetails()
        setupDismissableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        configTableView()
        addSemiTransparentBack()
        animateView(show: true)
    }
    
    func handleEarnBadgesTap(){
        self.dismiss(animated: true, completion: {
            if let vc = self.delegate as? ChatViewController{
                vc.displayKnownBadges()
            }
        })
    }
    
    func handleSatsButtonSend(){
        if let valid_message = message{
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
        let loadingViewFrame = detailView.frame
        
        loadingView = UIView(frame: loadingViewFrame)
        loadingView?.isUserInteractionEnabled = false
        loadingView?.backgroundColor = UIColor.Sphinx.Body
        
        if let loadingView = loadingView {
            let imageView : UIImageView = UIImageView(frame: tableView.frame)
            imageView.image = UIImage(named: "memberBadgeLoadingView")
            imageView.contentMode = .scaleAspectFit
            imageView.alpha = 0.5
            let shimmerView = ShimmerView(frame: loadingViewFrame)
            shimmerView.alpha = 0.065
            loadingView.addSubview(shimmerView)
            loadingView.addSubview(imageView)
            detailView.addSubview(loadingView)
            detailView.bringSubviewToFront(loadingView)
            tableView.isHidden = true
            shimmerView.startShimmerAnimation()
        }
    }
    
    func removeShimmerView(){
        tableView.isHidden = false
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
    
    func configTableView(){
        memberBadgeDetailVM.knownTribeBadges = self.knownTribeBadges
        memberBadgeDetailVM.message = self.message
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