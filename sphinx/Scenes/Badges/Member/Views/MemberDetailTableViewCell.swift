//
//  MemberBadgeDetailTableViewCell..swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

public enum MemberBadgeDetailCellType{
    case header
    case badges
    case reputation
    case details
    case contributions
    case earnings
}

class MemberDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    
    let badgeLimit = 4
    var subviewLabels : [UILabel?] = []
    var subviewImageViews : [UIImageView?] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(type:MemberBadgeDetailCellType,badges:[Badge],leaderboardData:ChatLeaderboardEntry?=nil,isExpanded:Bool){
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
        case .reputation:
            titleLabel.text = "Reputation:"
            break
        default:
            break
        }
        
        configureStackView(type: type,badges: badges, leaderboardData: leaderboardData, isExpanded: isExpanded)
    }
    
    override func prepareForReuse() {
        clearLabels()
        clearImageViews()
    }
    
    func clearLabels(){
        for label in subviewLabels.compactMap({$0}){
            label.text = ""
            label.removeFromSuperview()
        }
    }
    
    func clearImageViews(){
        for imageView in subviewImageViews.compactMap({$0}){
            imageView.image = nil
            imageView.removeFromSuperview()
        }
    }
    
    func configureStackView(type:MemberBadgeDetailCellType,badges:[Badge],leaderboardData:ChatLeaderboardEntry?=nil,isExpanded:Bool){
        var itemSpacing : CGFloat = 12.0
        switch(type){
            case .contributions:
                var satsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 97.0, height: stackView.frame.height))
                if let valid_leaderboard = leaderboardData,
                   let valid_sats_count = valid_leaderboard.spent{
                    let satsString = "\(valid_sats_count) sats"
                    let numLength = satsString.count - "sats".count
                    let satsWidth = (numLength <= 3) ? 97.0 : (97.0 + (CGFloat(numLength - 3) * 10.0))
                    satsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: satsWidth, height: stackView.frame.height))
                    let satsLabelAttributedText = NSMutableAttributedString(string: satsString)
                    satsLabelAttributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.BlueTextAccent, range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: numLength))
                    
                    satsLabelAttributedText.addAttribute(.font,value: UIFont(name: "Roboto", size: 15.0), range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: satsString.count))
                    satsLabel.attributedText = satsLabelAttributedText
                    satsLabel.textAlignment = .right
                }
                else{
                    satsLabel.text = ""
                }
                
                self.subviewLabels.append(satsLabel)
                stackView.addSubview(satsLabel)
                
                
                stackView.translatesAutoresizingMaskIntoConstraints = false
                var rankLabel = UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: 34.0, height: stackView.frame.height))
                if let valid_leaderboard = leaderboardData,
                   let valid_rank = valid_leaderboard.spentRank,
                   let valid_ordinal = valid_rank.ordinal{
                    let rankWidth = (valid_ordinal.count <= 3) ? 34.0 : (34.0 + (CGFloat(valid_ordinal.count - 3) * 10.0))
                    rankLabel =  UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: rankWidth, height: stackView.frame.height))
                    rankLabel.text = "\(valid_ordinal)"
                }
                else{
                    rankLabel.text = ""
                }
                rankLabel.font = UIFont(name: "Roboto", size: 15.0)
                rankLabel.textAlignment = .right
                rankLabel.textColor = UIColor.Sphinx.SecondaryText
                self.subviewLabels.append(rankLabel)
                stackView.addSubview(rankLabel)
            stackView.spacing = itemSpacing
            stackViewWidth.constant = rankLabel.frame.width + satsLabel.frame.width + itemSpacing
                self.layoutIfNeeded()
                break
            case .earnings:
                let satsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 97.0, height: stackView.frame.height))
                if let valid_leaderboard = leaderboardData,
                   let valid_sats_count = valid_leaderboard.earned{
                    let satsString = "\(valid_sats_count) sats"
                    let numLength = satsString.count - "sats".count
                    let satsLabelAttributedText = NSMutableAttributedString(string: satsString)
                    satsLabelAttributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.PrimaryGreen, range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: numLength))
                    
                    satsLabelAttributedText.addAttribute(.font,value: UIFont(name: "Roboto", size: 15.0), range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: satsString.count))
                    satsLabel.attributedText = satsLabelAttributedText
                    satsLabel.textAlignment = .right
                }
                else{
                    satsLabel.text = ""
                }
                
                self.subviewLabels.append(satsLabel)
                stackView.addSubview(satsLabel)
            
                
                
                stackView.translatesAutoresizingMaskIntoConstraints = false
                var rankLabel = UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: 34.0, height: stackView.frame.height))
                if let valid_leaderboard = leaderboardData,
                   let valid_rank = valid_leaderboard.earnedRank,
                   let valid_ordinal = valid_rank.ordinal{
                    let rankWidth = (valid_ordinal.count <= 3) ? 34.0 : (34.0 + (CGFloat(valid_ordinal.count - 3) * 10.0))
                    rankLabel =  UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: rankWidth, height: stackView.frame.height))
                    rankLabel.text = "\(valid_ordinal)"
                }
                else{
                    rankLabel.text = ""
                }
                rankLabel.font = UIFont(name: "Roboto", size: 15.0)
                rankLabel.textAlignment = .right
                rankLabel.textColor = UIColor.Sphinx.SecondaryText
                self.subviewLabels.append(rankLabel)
                stackView.spacing = itemSpacing
                stackView.addSubview(rankLabel)
                
                
            stackViewWidth.constant = rankLabel.frame.width + satsLabel.frame.width + itemSpacing
                self.layoutIfNeeded()
                break
            case .badges:
                itemSpacing = 8.0
                if(isExpanded == true){
                    clearLabels()
                    clearImageViews()
                    let disclosureImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: stackView.frame.height, height: stackView.frame.height))
                    disclosureImageView.image = UIImage(named: "disclosureIndicator")
                    disclosureImageView.transform = disclosureImageView.transform.rotated(by: .pi/2)
                    self.subviewImageViews.append(disclosureImageView)
                    stackView.addSubview(disclosureImageView)
                    stackViewWidth.constant = disclosureImageView.frame.width
                    self.layoutIfNeeded()
                    return
                }
            
                let imageUrls : [String] = badges.compactMap({$0.icon_url})
                var clippedUrls = [String]()
                for i in 0..<min(badgeLimit, imageUrls.count){
                    clippedUrls.append(imageUrls[i])
                }
                let imageWidth : CGFloat = 40.0
                var cursorValue : CGFloat = 0.0
                stackView.translatesAutoresizingMaskIntoConstraints = false
            
                for imageUrl in clippedUrls{
                    let image1 = UIImageView(frame: CGRect(x: cursorValue, y: 0.0, width: imageWidth, height: 40.0))
                    image1.sd_setImage(with: URL(string: imageUrl))
                    image1.makeCircular()
                    stackView.addSubview(image1)
                    self.subviewImageViews.append(image1)
                    
                    cursorValue += (imageWidth + itemSpacing)
                }
            
                if(imageUrls.count >= 3){
                    let bubble = UIView(frame: CGRect(x: cursorValue, y: 0.0, width: imageWidth, height: 40.0))
                    bubble.backgroundColor = UIColor.Sphinx.SecondaryText
                    let bubbleLabel = UILabel(frame: bubble.frame)
                    bubbleLabel.text = "+\(badges.count - badgeLimit)"
                    bubbleLabel.textColor = UIColor.Sphinx.MainBottomIcons
                    bubbleLabel.textAlignment = .center
                    bubble.makeCircular()
                    bubble.alpha = 0.1
                    stackView.addSubview(bubbleLabel)
                    stackView.addSubview(bubble)
                    cursorValue += (imageWidth + itemSpacing)
                }
                
                stackViewWidth.constant = cursorValue
                self.layoutIfNeeded()
                break
            case .reputation:
                stackView.translatesAutoresizingMaskIntoConstraints = false
                    let postsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: stackView.frame.height))
                    postsLabel.text = ""
                    if let valid_leaderboard = leaderboardData,
                       let valid_rep = valid_leaderboard.reputation{
                        postsLabel.text = "\(valid_rep)"
                    }
                    
                    postsLabel.font = UIFont(name: "Roboto", size: 15.0)
                    postsLabel.textColor = UIColor.Sphinx.BodyInverted
                    postsLabel.textAlignment = .right
                stackView.addSubview(postsLabel)
                stackViewWidth.constant = postsLabel.frame.width + itemSpacing
                self.subviewLabels.append(postsLabel)
                self.layoutIfNeeded()
                break
            default:
            
                break
        }
    }
    
}

// MARK: - Static Properties
extension MemberDetailTableViewCell {
    static let reuseID = "MemberBadgeDetailTableViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil)
    }()
}


private var ordinalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter
}()

extension Int {
    var ordinal: String? {
        return ordinalFormatter.string(from: NSNumber(value: self))
    }
}
