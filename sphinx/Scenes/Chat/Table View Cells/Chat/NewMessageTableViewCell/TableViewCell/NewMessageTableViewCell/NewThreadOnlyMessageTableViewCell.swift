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
                let newImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 23.0, height: 23.0))
                //newImageView.image = #imageLiteral(resourceName: "bluecheckmark")
                newImageView.sd_setImage(with: URL(string: message.senderPic ?? ""))
                newImageView.contentMode = .scaleAspectFill
                newImageView.makeCircular()
                avatarIconStackView.insertArrangedSubview(newImageView, at: 0)
                newImageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newImageView.widthAnchor.constraint(equalToConstant: 23.0),
                    newImageView.heightAnchor.constraint(equalToConstant: 23.0)
                ])
                newImageView.layer.borderColor = UIColor.Sphinx.Body.cgColor
                newImageView.layer.borderWidth = 2.0
                avatarIconStackView.sendSubviewToBack(newImageView)
            }
            if let firstMessage = threadMessages.filter({$0.isOriginalMessage == true}).first{
                firstResponseLabel.text = firstMessage.sendDate?.getLastMessageDateFormat()
                let ti :TimeInterval = 1626369200
                firstResponseLabel.text = Date(timeIntervalSince1970: ti).getThreadDateTime()
                contactAliasLabel.text = firstMessage.senderAlias
                senderAvatarImageView.sd_setImage(with: URL(string: firstMessage.senderPic ?? ""))
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
