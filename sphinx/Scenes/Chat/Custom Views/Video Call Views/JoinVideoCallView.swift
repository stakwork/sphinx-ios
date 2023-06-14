//
//  JoinVideoCallView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol JoinCallViewDelegate: class {
    func didTapCopyLink()
    func didTapAudioButton()
    func didTapVideoButton()
}

class JoinVideoCallView: UIView {
    
    weak var delegate: JoinCallViewDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var audioButtonContainer: UIView!
    @IBOutlet weak var videoButtonContainer: UIView!
    
    public enum CallButton: Int {
        case Audio
        case Video
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("JoinVideoCallView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        audioButtonContainer.layer.cornerRadius = 8
        audioButtonContainer.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.PrimaryBlueBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
        
        videoButtonContainer.layer.cornerRadius = 8
        videoButtonContainer.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.GreenBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
    }
    
    func configureWith(
        callLink: BubbleMessageLayoutState.CallLink,
        and delegate: JoinCallViewDelegate
    ) {
        self.delegate = delegate
        
        videoButtonContainer.isHidden = callLink.callMode == .Audio
    }
    
    func configure(delegate: JoinCallViewDelegate, link: String) {
        self.delegate = delegate
        
        configureWith(link: link)
    }
    
    func configureWith(link: String) {
        let mode = VideoCallHelper.getCallMode(link: link)
        
        audioButtonContainer.isHidden = false
        videoButtonContainer.isHidden = false
        
        switch (mode) {
        case .Audio:
            videoButtonContainer.isHidden = true
            break
        default:
            break
        }
    }
    
    @IBAction func callButtonTouched(_ sender: Any) {
        callButtonDeselected(sender)
        
        guard let sender = sender as? UIButton else {
            return
        }
        
        switch(sender.tag) {
        case CallButton.Audio.rawValue:
            delegate?.didTapAudioButton()
            break
        case CallButton.Video.rawValue:
            delegate?.didTapVideoButton()
            break
        default:
            break
        }
    }
    
    @IBAction func callButtonSelected(_ sender: Any) {
        guard let sender = sender as? UIButton else {
            return
        }
        
        switch(sender.tag) {
        case CallButton.Audio.rawValue:
            audioButtonContainer.backgroundColor = UIColor.Sphinx.PrimaryBlueBorder
            break
        case CallButton.Video.rawValue:
            videoButtonContainer.backgroundColor = UIColor.Sphinx.GreenBorder
            break
        default:
            break
        }
    }
    
    @IBAction func callButtonDeselected(_ sender: Any) {
        guard let sender = sender as? UIButton else {
            return
        }
        
        switch(sender.tag) {
        case CallButton.Audio.rawValue:
            audioButtonContainer.backgroundColor = UIColor.Sphinx.PrimaryBlue
            break
        case CallButton.Video.rawValue:
            videoButtonContainer.backgroundColor = UIColor.Sphinx.PrimaryGreen
            break
        default:
            break
        }
    }
    
    @IBAction func copyLinkButtonTouched() {
        delegate?.didTapCopyLink()
    }
}
