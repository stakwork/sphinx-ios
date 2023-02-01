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
    @IBOutlet weak var tableView: UITableView!
    
    
    var presentationContext : MemberBadgeDetailPresentationContext = .admin
    var delegate : TribeMemberViewDelegate? = nil
    var message : TransactionMessage? = nil
    var loadingView: UIView? = nil
    
    lazy var memberBadgeDetailVM : MemberBadgeDetailVM = {
       return MemberBadgeDetailVM(vc: self, tableView: tableView)
    }()
    
    static func instantiate(
        rootViewController: RootViewController,
        message: TransactionMessage,
        delegate: TribeMemberViewDelegate
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.memberBadgeDetailVC.instantiate()
        viewController.view.backgroundColor = .clear
        if let vc = viewController as? MemberBadgeDetailVC{
            vc.message = message
            vc.delegate = delegate
        }
        
        return viewController
    }
    
    override func viewDidLoad() {
        dismissBadgeDetails()
        detailView.backgroundColor = UIColor.Sphinx.Body
    }
    
    override func viewDidAppear(_ animated: Bool) {
        configTableView()
    }
    
    @IBAction func sendSatsButtonTapped(_ sender: Any) {
        
    }
    
    func handleSatsButtonSend(message:TransactionMessage){
        self.dismiss(animated: false,completion: {
            self.delegate?.shouldGoToSendPayment(message: message)
        })
    }
    
    func addShimmerLoadingView(){
        let loadingViewFrame = detailView.frame
        loadingView = UIView(frame: loadingViewFrame)
        loadingView?.isUserInteractionEnabled = false
        loadingView?.backgroundColor = UIColor.Sphinx.Body
        if let loadingView = loadingView{
            let imageView : UIImageView = UIImageView(frame: loadingView.frame)
            imageView.image = UIImage(named: "memberBadgeLoadingView")
            imageView.contentMode = .scaleAspectFit
            let shimmerView = ShimmerView(frame: imageView.frame)
            shimmerView.alpha = 0.075
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
        memberBadgeDetailVM.message = self.message
        memberBadgeDetailVM.configTable()
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
    }
    
    
    func dismissBadgeDetails(){
        detailView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        detailViewHeight.constant = (memberBadgeDetailVM.badges.count > 0) ? 492.0 : 444.0
        UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
            self.detailView.layoutIfNeeded()
        })
    }
    
    func expandBadgeDetail(){
        detailView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = true
        detailViewHeight.constant = self.view.frame.height * 0.9
        UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
            self.detailView.layoutIfNeeded()
        })
    }
    
    
}
