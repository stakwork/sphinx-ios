//
//  GroupRequestView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class GroupRequestView: UIView {
    
    weak var delegate: GroupActionsViewDelegate?

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("GroupRequestView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        messageView.layer.cornerRadius = 8
        messageView.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        messageView.layer.borderWidth = 1
        
        doneButton.layer.cornerRadius = doneButton.bounds.height / 2
        cancelButton.layer.cornerRadius = cancelButton.bounds.height / 2
    }
    
    func configureWith(
        status: NoBubbleMessageLayoutState.GroupMemberRequest.MemberRequestStatus,
        isActiveMember: Bool,
        senderAlias: String,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        self.delegate = delegate
        
        let rejected = status == NoBubbleMessageLayoutState.GroupMemberRequest.MemberRequestStatus.Rejected
        let approved = status == NoBubbleMessageLayoutState.GroupMemberRequest.MemberRequestStatus.Approved
        let pending = !rejected && !approved
        
        doneButton.isEnabled = !isActiveMember && pending
        cancelButton.isEnabled = !isActiveMember && pending

        doneButton.alpha = rejected ? 0.3 : 1.0
        cancelButton.alpha = approved ? 0.3 : 1.0
        
        if approved {
            messageLabel.text = String(format: "admin.request.approved".localized, senderAlias)
        } else if rejected {
            messageLabel.text = String(format: "admin.request.rejected".localized, senderAlias)
        } else {
            messageLabel.text = String(format: "member.request".localized, senderAlias)
        }
    }
    
    @IBAction func doneButtonTouched() {
        delegate?.didTapApproveRequestButton()
    }
    
    @IBAction func cancelButtonTouched() {
        delegate?.didTapRejectRequestButton()
    }
    
}
