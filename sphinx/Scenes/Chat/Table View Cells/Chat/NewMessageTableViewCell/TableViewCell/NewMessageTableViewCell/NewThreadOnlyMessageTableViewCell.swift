//
//  NewThreadOnlyMessageTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/18/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class NewThreadOnlyMessageTableViewCell: UITableViewCell,ChatTableViewCellProtocol {

    @IBOutlet weak var senderAvatarImageView: UIImageView!
    @IBOutlet weak var contactAliasLabel: UILabel!
    @IBOutlet weak var firstThreadMessageLabel: UILabel!
    @IBOutlet weak var firstResponseLabel: UILabel!
    @IBOutlet weak var replyCountLabel: UILabel!
    @IBOutlet weak var lastResponseLabel: UILabel!
    @IBOutlet weak var horizontalStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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
        
        senderAvatarImageView.makeCircular()
        firstThreadMessageLabel.text = messageCellState.messageString
                
        var cellState = messageCellState
        
        if let threadMessages = cellState.threadMessageArray?.threadMessages {
            for message in threadMessages.filter({$0.isOriginalMessage == false}) {
                // Perform actions with each threadMessage
                let newImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 23.0, height: 23.0))
                //newImageView.image = #imageLiteral(resourceName: "bluecheckmark")
                newImageView.sd_setImage(with: URL(string: message.senderPic ?? ""))
                newImageView.contentMode = .scaleAspectFill
                newImageView.makeCircular()
                horizontalStackView.insertArrangedSubview(newImageView, at: 0)
                newImageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newImageView.widthAnchor.constraint(equalToConstant: 23.0),
                    newImageView.heightAnchor.constraint(equalToConstant: 23.0)
                ])
            }
            if let firstMessage = threadMessages.filter({$0.isOriginalMessage == true}).first{
                firstResponseLabel.text = firstMessage.sendDate?.publishDateString
                contactAliasLabel.text = firstMessage.senderAlias
                senderAvatarImageView.sd_setImage(with: URL(string: firstMessage.senderPic ?? ""))
                senderAvatarImageView.contentMode = .scaleAspectFill
            }
            lastResponseLabel.text = threadMessages.last?.sendDate?.publishDateString
        }
        
        horizontalStackView.superview?.layoutIfNeeded()
        replyCountLabel.text = getReplyCountText(threadMessageCount: messageCellState.threadMessages.count)
        
        print(messageCellState)
        
        
    }
}
