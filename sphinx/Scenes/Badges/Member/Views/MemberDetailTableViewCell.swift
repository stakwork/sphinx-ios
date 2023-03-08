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
    @IBOutlet weak var stackViewTrailingConstraint: NSLayoutConstraint!
    
    let badgeLimit = 4
    var subviewLabels : [UILabel?] = []
    var subviewImageViews : [UIImageView?] = []
    var itemSpacing : CGFloat = 12.0
    
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
            titleLabel.text = "\("badges.badges".localized):"
            break
        case .contributions:
            titleLabel.text = "\("badges.contributions".localized):"
            break
        case .earnings:
            titleLabel.text = "\("badges.earnings".localized):"
            break
        case .reputation:
            titleLabel.text = "\("badges.reputation".localized):"
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
        let baseOffset : CGFloat = -8
        switch(type){
            case .contributions:
                configRankedStackViewParams(leaderboardData: leaderboardData, type: .contributions)
                stackViewTrailingConstraint.constant = 14 + baseOffset
                self.layoutIfNeeded()
                break
            case .earnings:
                configRankedStackViewParams(leaderboardData: leaderboardData, type: .earnings)
                stackViewTrailingConstraint.constant = 14 + baseOffset
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
                    let bitmapSize = CGSize(width: 500, height: 500)
                    let defaultImage = #imageLiteral(resourceName: "appPinIcon")
                    let image1 = UIImageView(frame: CGRect(x: cursorValue, y: 0.0, width: imageWidth, height: 40.0))

                    image1.sd_setImage(
                        with: URL(string: imageUrl),
                        placeholderImage: defaultImage,
                        options: [],
                        context: [.imageThumbnailPixelSize : bitmapSize]
                    )
                    
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
                stackViewTrailingConstraint.constant = baseOffset
                self.layoutIfNeeded()
                break
            case .reputation:
                stackView.translatesAutoresizingMaskIntoConstraints = false
                    let postsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: stackView.frame.height))
                    postsLabel.text = ""
                    if let valid_leaderboard = leaderboardData,
                       let valid_rep = valid_leaderboard.reputation {
                        postsLabel.text = "\(valid_rep)"
                    }
                    
                    postsLabel.font = UIFont(name: "Roboto", size: 15.0)
                    postsLabel.textColor = UIColor.Sphinx.BodyInverted
                    postsLabel.textAlignment = .right
                stackView.addSubview(postsLabel)
                stackViewWidth.constant = postsLabel.frame.width + itemSpacing
                self.subviewLabels.append(postsLabel)
                stackViewTrailingConstraint.constant = 4 + baseOffset
                self.layoutIfNeeded()
                break
            default:
                break
        }
        
    }
    
    func configRankedStackViewParams(shouldIncludeRank:Bool=false,leaderboardData:ChatLeaderboardEntry?,type:MemberBadgeDetailCellType){
        
        //1. Configure row specific data
        var color : UIColor!
        var relevantStat : Int!
        var relevnantRank : String!
        var relevantLeaderboardEntry : ChatLeaderboardEntry = leaderboardData ?? ChatLeaderboardEntry()
        
        if(type == .earnings){
            color = UIColor.Sphinx.PrimaryGreen
            if let stat = relevantLeaderboardEntry.earned,
               let valid_rank = relevantLeaderboardEntry.earnedRank,
               let valid_ordinal = valid_rank.ordinal{
                relevantStat = stat
                relevnantRank = valid_ordinal
            }
            else if(shouldIncludeRank == false),
                let stat = relevantLeaderboardEntry.earned{
                relevantStat = stat
            }
            else{
                return
            }
        }
        else if(type == .contributions){
            color = UIColor.Sphinx.BlueTextAccent
            if let stat = relevantLeaderboardEntry.spent,
               let valid_rank = relevantLeaderboardEntry.spentRank,
               let valid_ordinal = valid_rank.ordinal{
                relevantStat = stat
                relevnantRank = valid_ordinal
            }
            else if(shouldIncludeRank == false),
                let stat = relevantLeaderboardEntry.spent{
                relevantStat = stat
            }
            else{
                return
            }
        }
        
        //2. Construct the UI
        let satsLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 97.0, height: stackView.frame.height))
        let satsString = "\(String(describing: relevantStat!)) sats"
        let numLength = satsString.count - "sats".count
        let satsLabelAttributedText = NSMutableAttributedString(string: satsString)
        satsLabelAttributedText.addAttribute(.foregroundColor, value: color, range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: numLength))
        
        satsLabelAttributedText.addAttribute(.font, value: UIFont(name: "Roboto", size: 15.0)!, range: NSRange(location: satsString.distance(from: String.Index(utf16Offset: 0, in: satsString), to: String.Index(utf16Offset: 0, in: satsString)), length: satsString.count))
        
        satsLabel.attributedText = satsLabelAttributedText
        satsLabel.textAlignment = .right
        
        self.subviewLabels.append(satsLabel)
        stackView.addSubview(satsLabel)
        stackViewWidth.constant = satsLabel.frame.width
        
        if(shouldIncludeRank == true){
            stackView.translatesAutoresizingMaskIntoConstraints = false
            var rankLabel = UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: 34.0, height: stackView.frame.height))
            let rankWidth = (relevnantRank.count <= 3) ? 34.0 : (34.0 + (CGFloat(relevnantRank.count - 3) * 10.0))
            rankLabel =  UILabel(frame: CGRect(x: satsLabel.frame.width, y: 0.0, width: rankWidth, height: stackView.frame.height))
            rankLabel.text = "\(String(describing: relevnantRank!))"
            rankLabel.font = UIFont(name: "Roboto", size: 15.0)
            rankLabel.textAlignment = .right
            rankLabel.textColor = UIColor.Sphinx.SecondaryText
            self.subviewLabels.append(rankLabel)
            stackView.spacing = itemSpacing
            stackView.addSubview(rankLabel)
            stackViewWidth.constant = rankLabel.frame.width + satsLabel.frame.width + itemSpacing
        }
        self.layoutIfNeeded()
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
