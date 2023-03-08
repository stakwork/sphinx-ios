//
//  MemberBadgeHeaderCell.swift
//  sphinx
//
//  Created by James Carucci on 2/1/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MemberBadgeHeaderCell: UITableViewCell {
    
    @IBOutlet weak var memberNameLabel: UILabel!
    @IBOutlet weak var memberDescriptionLabel: UILabel!
    @IBOutlet weak var sendSatsButton: UIButton!
    @IBOutlet weak var earnBadgesButton: UIButton!
    @IBOutlet weak var moderatorLabel: UILabel!
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    
    var presentingVC : MemberBadgeDetailVC?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        //Send Sats
        sendSatsButton.layer.cornerRadius = sendSatsButton.frame.height/2.0
        sendSatsButton.titleLabel?.font = UIFont(name: "Roboto", size: 14.0)
        sendSatsButton.setTitle("badges.send-sats".localized, for: .normal)
        

        //Earn Badges
        earnBadgesButton.setTitle("badges.earn-badges".localized, for: .normal)
        earnBadgesButton.titleLabel?.font = UIFont(name: "Roboto", size: 14.0)
        earnBadgesButton.layer.borderWidth = 1.0
        earnBadgesButton.layer.borderColor = UIColor.Sphinx.MainBottomIcons.cgColor
        earnBadgesButton.layer.cornerRadius = earnBadgesButton.frame.height/2.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func sendSatsTapped(_ sender: Any) {
        presentingVC?.handleSatsButtonSend()
    }
    
    @IBAction func earnBadgesTapped(_ sender: Any) {
        presentingVC?.handleEarnBadgesTap()
    }
    
}

// MARK: - Static Properties
extension MemberBadgeHeaderCell {
    static let reuseID = "MemberBadgeHeaderCell"
    
    static let nib: UINib = {
        UINib(nibName: "MemberBadgeHeaderCell", bundle: nil)
    }()
}

extension MemberBadgeHeaderCell {
    
    func configureHeaderView(
        presentingVC: MemberBadgeDetailVC?,
        personInfo: TribeMemberStruct,
        message: TransactionMessage?,
        isModerator: Bool
    ){
        self.presentingVC = presentingVC
        
        self.moderatorLabel.text = (isModerator ? "member-profile.moderator" : "member-profile.tribe-member").localized
        self.memberNameLabel.text = personInfo.ownerAlias
        self.memberDescriptionLabel.text = personInfo.description
        
        self.chatAvatarView.configureForUserWith(
            color: UIColor.random(),
            alias: personInfo.ownerAlias,
            picture: personInfo.img
        )
        self.chatAvatarView.setInitialLabelSize(size: 30)
    }
}
