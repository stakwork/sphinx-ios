//
//  TribeMemberProfileView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 14/11/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol TribeMemberProfileViewDelegate: class {
    func didTapSendSats()
    func dismissLineWasDragged(gestureRecognizer: UIPanGestureRecognizer, view: UIView)
}

class TribeMemberProfileView: UIView {
    
    weak var delegate: TribeMemberProfileViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var dismissLine: UIView!
    @IBOutlet weak var dismissLineContainer: UIView!
    @IBOutlet weak var avatarView: ChatAvatarView!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var aliasLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var sendSatsContainer: UIView!
    @IBOutlet weak var priceToMeetValueLabel: UILabel!
    @IBOutlet weak var codingLanguagesValueLabel: UILabel!
    @IBOutlet weak var postsValueLabel: UILabel!
    @IBOutlet weak var twitterValueLabel: UILabel!
    @IBOutlet weak var githubValueLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("TribeMemberProfileView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        setupViews()
    }
    
    func setupViews() {
        dismissLine.layer.cornerRadius = dismissLine.frame.height / 2
        dismissLine.clipsToBounds = true
        
        sendSatsContainer.layer.cornerRadius = sendSatsContainer.frame.height / 2
        sendSatsContainer.clipsToBounds = true
        
        avatarView.setInitialLabelSize(size: 30)
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged))
        dismissLineContainer.addGestureRecognizer(gesture)
        dismissLineContainer.isUserInteractionEnabled = true
    }
    
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        self.delegate?.dismissLineWasDragged(gestureRecognizer: gestureRecognizer, view: dismissLineContainer)
    }
    
    func configureWith(tribeMember: TribeMemberStruct) {
        
        avatarView.configureForUserWith(
            color: UIColor.random(),
            alias: tribeMember.uniqueName,
            picture: tribeMember.img
        )
        
        aliasLabel.text = tribeMember.uniqueName
        descriptionLabel.text = tribeMember.description
        
        priceToMeetValueLabel.text = String(tribeMember.priceToMeet)
        codingLanguagesValueLabel.text = tribeMember.extras?.codingLanguagesString ?? "-"
        postsValueLabel.text = tribeMember.extras?.postsString ?? "0"
        twitterValueLabel.text = tribeMember.extras?.twitterString ?? "-"
        githubValueLabel.text = tribeMember.extras?.githubString ?? "-"
    }
    
    @IBAction func sendSatsButtonTapped() {
        delegate?.didTapSendSats()
    }
    
}
