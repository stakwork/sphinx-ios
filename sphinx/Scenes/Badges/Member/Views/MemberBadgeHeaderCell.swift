//
//  MemberBadgeHeaderCell.swift
//  sphinx
//
//  Created by James Carucci on 2/1/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MemberBadgeHeaderCell: UITableViewCell {
    
    @IBOutlet weak var memberImageView: UIImageView!
    @IBOutlet weak var memberNameLabel: UILabel!
    @IBOutlet weak var sendSatsButton: UIButton!
    @IBOutlet weak var earnBadgesButton: UIButton!
    @IBOutlet weak var moderatorBadgeImageView: UIImageView!
    @IBOutlet weak var moderatorLabel: UILabel!
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    
    var presentingVC : MemberBadgeDetailVC?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initHeaderView(presentingVC:MemberBadgeDetailVC){
        self.presentingVC = presentingVC
        //Member Image
        memberImageView.contentMode = .scaleAspectFill
        memberImageView.makeCircular()
        
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

extension MemberBadgeHeaderCell: MemberBadgeDetailVMDisplayDelegate{
    func reloadHeaderView(personInfo:TribeMemberStruct,message:TransactionMessage?){
        self.memberNameLabel.text = personInfo.ownerAlias
        if let valid_message = message{
            self.chatAvatarView.configureForSenderWith(message: valid_message)
            self.chatAvatarView.setInitialLabelSize(size: 30)
        }
        else{
            self.chatAvatarView.isHidden = true
        }
    }
    
    func getImageViewReference()->UIImageView{
        return memberImageView
    }
    
}
