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
    
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var memberNameLabel: UILabel!
    @IBOutlet weak var sendSatsButton: UIButton!
    @IBOutlet weak var earnBadgesButton: UIButton!
    @IBOutlet weak var detailViewHeight: NSLayoutConstraint!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var moderatorBadgeImageView: UIImageView!
    
    
    var presentationContext : MemberBadgeDetailPresentationContext = .admin
    var message : TransactionMessage? = nil
    var delegate : TribeMemberViewDelegate? = nil
    
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
        configHeaderView()
        configTableView()
        dismissBadgeDetails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadProfileData()
    }
    
    @IBAction func sendSatsButtonTapped(_ sender: Any) {
        if let valid_message = message{
            self.dismiss(animated: false,completion: {
                self.delegate?.shouldGoToSendPayment(message: valid_message)
            })
        }
    }
    
    
    func configHeaderView(){
        detailView.backgroundColor = UIColor.Sphinx.Body
        //Member Image
        memberImageView.contentMode = .scaleAspectFill
        memberImageView.sd_setImage(with: URL(string: "https://us.123rf.com/450wm/fizkes/fizkes2010/fizkes201001384/fizkes201001384.jpg?ver=6"))
        memberImageView.makeCircular()
        
        //Send Sats
        sendSatsButton.layer.cornerRadius = sendSatsButton.frame.height/2.0
        sendSatsButton.titleLabel?.font = UIFont(name: "Roboto", size: 14.0)

        //Earn Badges
        earnBadgesButton.titleLabel?.font = UIFont(name: "Roboto", size: 14.0)
        earnBadgesButton.layer.borderWidth = 1.0
        earnBadgesButton.layer.borderColor = UIColor.Sphinx.MainBottomIcons.cgColor
        earnBadgesButton.layer.cornerRadius = earnBadgesButton.frame.height/2.0
        
    }
    
    func configTableView(){
        memberBadgeDetailVM.configTable()
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
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
    
    func configView(personInfo:TribeMemberStruct){
        print(personInfo)
        self.memberImageView.sd_setImage(with: URL(string: personInfo.img))
        self.memberNameLabel.text = personInfo.ownerAlias
    }
    
    func loadProfileData() {
        guard let person = message?.person else {
            //dismissView()
            return
        }
        
        API.sharedInstance.getTribeMemberInfo(person: person, callback: { (success, personInfo) in
            if let personInfo = personInfo, success {
                self.configView(personInfo: personInfo)
            } else {
                //self.dismissView()
            }
        })
    }
    
}
