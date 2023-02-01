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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initHeaderView(){
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
    
}

// MARK: - Static Properties
extension MemberBadgeHeaderCell {
    static let reuseID = "MemberBadgeHeaderCell"
    
    static let nib: UINib = {
        UINib(nibName: "MemberBadgeHeaderCell", bundle: nil)
    }()
}

extension MemberBadgeHeaderCell: MemberBadgeDetailVMDisplayDelegate{
    func reloadHeaderView(personInfo:TribeMemberStruct){
        print(personInfo)
        self.memberNameLabel.text = personInfo.ownerAlias
    }
    
    func getImageViewReference()->UIImageView{
        return memberImageView
    }
    
}
