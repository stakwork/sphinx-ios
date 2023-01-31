//
//  MemberBadgeDetailTableViewCell..swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

public enum MemberBadgeDetailCellType{
    case badges
    case posts
    case contributions
    case earnings
}

class MemberBadgeDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(type:MemberBadgeDetailCellType){
        switch(type){
        case .badges:
            titleLabel.text = "Badges:"
            break
        case .contributions:
            titleLabel.text = "Contributions:"
            break
        case .earnings:
            titleLabel.text = "Earnings:"
            break
        case .posts:
            titleLabel.text = "Posts:"
            break
        }
        
        configureStackView(type: type)
    }
    
    func configureStackView(type:MemberBadgeDetailCellType){
        switch(type){
            case .contributions:
                let satsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 97.0, height: stackView.frame.height))
                let satsString = "5000 sats"
                let numLength = satsString.count - "sats".count
                let satsLabelAttributedText = NSMutableAttributedString(string: satsString)
                satsLabelAttributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.BlueTextAccent, range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: numLength))
                
                satsLabelAttributedText.addAttribute(.font,value: UIFont(name: "Roboto", size: 15.0), range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: satsString.count))
                satsLabel.attributedText = satsLabelAttributedText
                satsLabel.textAlignment = .right
                stackView.addSubview(satsLabel)
                
                
                stackView.translatesAutoresizingMaskIntoConstraints = false
                let rankLabel = UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: 34.0, height: stackView.frame.height))
                rankLabel.text = "6th"
                rankLabel.font = UIFont(name: "Roboto", size: 15.0)
                rankLabel.textAlignment = .right
                rankLabel.textColor = UIColor.Sphinx.SecondaryText
                stackView.addSubview(rankLabel)
                
                stackViewWidth.constant = rankLabel.frame.width + satsLabel.frame.width
                self.layoutIfNeeded()
                break
            case .earnings:
                let satsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 97.0, height: stackView.frame.height))
                let satsString = "3000 sats"
                let numLength = satsString.count - "sats".count
                let satsLabelAttributedText = NSMutableAttributedString(string: satsString)
                satsLabelAttributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.PrimaryGreen, range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: numLength))
                
                satsLabelAttributedText.addAttribute(.font,value: UIFont(name: "Roboto", size: 15.0), range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: satsString.count))
                satsLabel.attributedText = satsLabelAttributedText
                satsLabel.textAlignment = .right
                stackView.addSubview(satsLabel)
                
                
                stackView.translatesAutoresizingMaskIntoConstraints = false
                let rankLabel = UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: 34.0, height: stackView.frame.height))
                rankLabel.text = "8th"
                rankLabel.font = UIFont(name: "Roboto", size: 15.0)
                rankLabel.textAlignment = .right
                rankLabel.textColor = UIColor.Sphinx.SecondaryText
                stackView.addSubview(rankLabel)
                
                
                stackViewWidth.constant = rankLabel.frame.width + satsLabel.frame.width
                self.layoutIfNeeded()
                break
            case .badges:
                
                break
            case .posts:
                stackView.translatesAutoresizingMaskIntoConstraints = false
                    let postsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: stackView.frame.height))
                    postsLabel.text = "150"
                    postsLabel.font = UIFont(name: "Roboto", size: 15.0)
                    postsLabel.textColor = UIColor.Sphinx.BodyInverted
                    postsLabel.textAlignment = .right
                stackView.addSubview(postsLabel)
                stackViewWidth.constant = postsLabel.frame.width
                self.layoutIfNeeded()
                break
        }
    }
    
}

// MARK: - Static Properties
extension MemberBadgeDetailTableViewCell {
    static let reuseID = "MemberBadgeDetailTableViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil)
    }()
}
