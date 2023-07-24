//
//  NewThreadOnlyMessageTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/18/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol NewThreadOnlyMessageTableViewCellDelegate : NSObject{
    func didTapOnThread(threadUUID:String)
}

class NewThreadOnlyMessageTableViewCell: UITableViewCell,ChatTableViewCellProtocol {

    @IBOutlet weak var senderAvatarImageView: UIImageView!
    @IBOutlet weak var contactAliasLabel: UILabel!
    @IBOutlet weak var firstThreadMessageLabel: UILabel!
    @IBOutlet weak var firstResponseLabel: UILabel!
    @IBOutlet weak var replyCountLabel: UILabel!
    @IBOutlet weak var lastResponseLabel: UILabel!
    @IBOutlet weak var detailsStackView: UIStackView!
    @IBOutlet weak var avatarIconStackView: UIStackView!
    @IBOutlet weak var initialsLabel : UILabel!
    
    
    var delegate : NewThreadOnlyMessageTableViewCellDelegate? = nil
    var threadUUID:String? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.threadUUID = nil
        for item in avatarIconStackView.arrangedSubviews{
            item.removeFromSuperview()
        }
    }
    
    func getReplyCountText(threadMessageCount:Int)->String{
        if(threadMessageCount == 1){
            return "1 reply"
        }
        else{
            return "\(String(describing: threadMessageCount)) replies"
        }
    }
    
    
    func configureWith(messageCellState: MessageTableCellState, mediaData: MessageTableCellState.MediaData?, tribeData: MessageTableCellState.TribeData?, linkData: MessageTableCellState.LinkData?, botWebViewData: MessageTableCellState.BotWebViewData?, uploadProgressData: MessageTableCellState.UploadProgressData?, delegate: NewMessageTableViewCellDelegate?, searchingTerm: String?, indexPath: IndexPath) {
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleThreadTap)))
        
        senderAvatarImageView.makeCircular()
        firstThreadMessageLabel.text = messageCellState.messageString
        
        initialsLabel.layer.cornerRadius = initialsLabel.frame.size.height/2
        initialsLabel.clipsToBounds = true
        
        var cellState = messageCellState
        let maxNumAvatars = 6
        if let threadMessages = cellState.threadMessageArray?.threadMessages {
            var shownSenderUUIDs = [Int]()
            var overflowSenderUUIDs = [Int]()
            for message in threadMessages.filter({$0.isOriginalMessage == false}) {
                // Perform actions with each threadMessage
                if shownSenderUUIDs.contains(where: {$0 == message.senderUUID})
                    { //don't count same user twice
                    
                    continue
                }
                else if shownSenderUUIDs.count >= maxNumAvatars{//cap at 6 shown reply users
                    overflowSenderUUIDs.append(message.senderUUID)
                    continue
                }
                shownSenderUUIDs.append(message.senderUUID)
                let newView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 23.0, height: 23.0))
                if let path = message.senderPic{
                    let newImageView = UIImageView(frame: newView.frame)
                    //newImageView.image = #imageLiteral(resourceName: "bluecheckmark")
                    let url = URL(string: path)
                    newImageView.sd_setImage(with: url)
                    newImageView.contentMode = .scaleAspectFill
                    newImageView.makeCircular()
                    newImageView.translatesAutoresizingMaskIntoConstraints = false
                    newImageView.layer.borderColor = UIColor.Sphinx.Body.cgColor
                    newImageView.layer.borderWidth = 2.0
                    newView.addSubview(newImageView)
                    
                    NSLayoutConstraint.activate([
                        newImageView.widthAnchor.constraint(equalToConstant: 23.0),
                        newImageView.heightAnchor.constraint(equalToConstant: 23.0),
                        newImageView.centerYAnchor.constraint(equalTo: newView.centerYAnchor)
                    ])
                }
                else{
                    let newInitialsLabel = UILabel(frame: newView.frame)
                    newInitialsLabel.layer.cornerRadius = initialsLabel.frame.size.height/2
                    newInitialsLabel.clipsToBounds = true
                    
                    newInitialsLabel.backgroundColor = message.senderColor
                    newInitialsLabel.textColor = UIColor.white
                    newInitialsLabel.text = message.senderAlias?.getInitialsFromName()
                    newInitialsLabel.textAlignment = .center
                    newInitialsLabel.makeCircular()
                    newInitialsLabel.font = UIFont(name: "Montserrat-Regular", size: replyCountLabel.font.pointSize)
                    newView.addSubview(newInitialsLabel)
                    
                    NSLayoutConstraint.activate([
                        newInitialsLabel.widthAnchor.constraint(equalToConstant: 23.0),
                        newInitialsLabel.heightAnchor.constraint(equalToConstant: 23.0),
                        newInitialsLabel.centerYAnchor.constraint(equalTo: newView.centerYAnchor)
                    ])
                }
                avatarIconStackView.insertArrangedSubview(newView, at: 0)
                avatarIconStackView.sendSubviewToBack(newView)
                
            }
            if let firstMessage = threadMessages.filter({$0.isOriginalMessage == true}).first{
                firstResponseLabel.text = firstMessage.sendDate?.getThreadDateTime()
                contactAliasLabel.text = firstMessage.senderAlias
                if let path = firstMessage.senderPic{
                    let avatarURL = URL(string: path)
                    senderAvatarImageView.sd_setImage(with: avatarURL)
                    senderAvatarImageView.makeCircular()
                }
                else{
                    senderAvatarImageView.isHidden = true
                    initialsLabel.isHidden = false
                    initialsLabel.backgroundColor = firstMessage.senderColor
                    initialsLabel.textColor = UIColor.white
                    initialsLabel.text = firstMessage.senderAlias?.getInitialsFromName()
                }
                senderAvatarImageView.contentMode = .scaleAspectFill
                self.threadUUID = firstMessage.threadUUID
            }
            lastResponseLabel.text = threadMessages.last?.sendDate?.publishDateString
            
            if(overflowSenderUUIDs.count > 0){
                let chosenSubview = avatarIconStackView.arrangedSubviews[maxNumAvatars-1]
                
                let shadowSubview = UIView(frame: chosenSubview.frame)
                shadowSubview.backgroundColor = UIColor.Sphinx.Body
                shadowSubview.layer.opacity = 0.75
                chosenSubview.addSubview(shadowSubview)
                
                let label = UILabel()
                label.frame = chosenSubview.frame
                label.textColor = UIColor.Sphinx.Text
                label.textAlignment = .center
                label.font = UIFont(name: "Roboto-Regular", size: 11)
                label.text = "+\(overflowSenderUUIDs.count)"
                chosenSubview.addSubview(label)
            }
        }
        
        detailsStackView.superview?.layoutIfNeeded()
        replyCountLabel.text = getReplyCountText(threadMessageCount: messageCellState.threadMessages.count)
        
        print(messageCellState)
        
        
    }
    
    @objc func handleThreadTap(){
        if let threadUUID = threadUUID{
            delegate?.didTapOnThread(threadUUID: threadUUID)
        }
    }
    
}
