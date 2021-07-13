//
//  BoostFireworksAnimationView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import Lottie

protocol AnimationViewDelegate : class {
    func animationDidFinish()
}

class BoostFireworksAnimationView: UIView {
    
    weak var delegate: AnimationViewDelegate?

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var boostContainer: UIView!
    @IBOutlet weak var boostAmountLabel: UILabel!
    @IBOutlet weak var boostIconCircle: UIView!
    @IBOutlet weak var boostIcon: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("BoostFireworksAnimationView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        initialsLabel.layer.cornerRadius = initialsLabel.frame.height / 2
        boostContainer.layer.cornerRadius = boostContainer.frame.height / 2
        boostIconCircle.layer.cornerRadius = boostIconCircle.frame.height / 2
        
        profileImageView.clipsToBounds = true
        initialsLabel.clipsToBounds = true
    }
    
    func configureWith(amount: Int, user: UserContact? = nil, delegate: AnimationViewDelegate) -> Bool {
        self.delegate = delegate
        
        let animationUser = user ?? UserContact.getOwner()
        if let animationUser = animationUser {
            self.boostAmountLabel.text = "\(amount)"
            configureImageOrInitials(contact: animationUser)
            runAnimation()
            return true
        }
        return false
    }
    
    func runAnimation() {
        let fireworksAnimation = Animation.named("fireworks")
        animationView.animation = fireworksAnimation
        animationView.play { (finished) in
            self.delegate?.animationDidFinish()
        }
    }
    
    func getImageUrl(contact: UserContact) -> String? {
        if let url = contact.getPhotoUrl(), !url.isEmpty {
            return url.removeDuplicatedProtocol()
        }
        return nil
    }
    
    func configureImageOrInitials(contact: UserContact) {
        profileImageView.isHidden = true
        initialsLabel.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        showInitialsFor(contact: contact)
        
        if let imageUrl = getImageUrl(contact: contact)?.trim(), let nsUrl = URL(string: imageUrl) {
            MediaLoader.asyncLoadImage(imageView: profileImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"), completion: { image in
                self.initialsLabel.isHidden = true
                self.profileImageView.isHidden = false
                self.profileImageView.image = image
            }, errorCompletion: { _ in })
        }
    }
    
    func showInitialsFor(contact: UserContact) {
        let name = contact.nickname ?? ""
        let color = contact.getColor()
        
        initialsLabel.isHidden = false
        initialsLabel.backgroundColor = color
        initialsLabel.textColor = UIColor.white
        initialsLabel.text = name.getInitialsFromName()
    }

}
