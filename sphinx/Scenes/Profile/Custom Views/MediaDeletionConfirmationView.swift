//
//  MediaDeletionConfirmationView.swift
//  sphinx
//
//  Created by James Carucci on 6/1/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


protocol MediaDeletionConfirmationViewDelegate : NSObject{
    func mediaDeletionCancelTapped()
    func mediaDeletionConfirmTapped()
}

public enum MediaDeletionConfirmationViewState{
    case awaitingApproval
    case loading
    case finished
}

class MediaDeletionConfirmationView: UIView {
    
    @IBOutlet weak var deletionSymbolContainerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deletionButton: UIButton!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var deletionSymbol: UIImageView!
    @IBOutlet weak var loadingCircularProgressView: CircularProgressView!
    @IBOutlet weak var gotItButton: UIButton!
    
    var batchState : ProfileManageStorageSpecificChatOrContentFeedItemVCState? = nil
    var spaceFreedString:String = "unknown"
    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleToTitleConstraintSpacing: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var subtitleLeading: NSLayoutConstraint!
    
    var source : StorageManagerMediaSource? = nil
    var state : MediaDeletionConfirmationViewState = .awaitingApproval{
        didSet{
            switch(state){
            case .awaitingApproval:
                moveToAwaitingApproval()
                break
            case .loading:
                moveToLoadingUI()
                break
            case .finished:
                moveToFinishedUI()
                break
            }
        }
    }
    var delegate : MediaDeletionConfirmationViewDelegate? = nil
    var type: StorageManagerMediaType? = nil {
        didSet{
           if let typeString = getContentTypeString(){
                let warningMessage = String(format: NSLocalizedString("deletion.warning.title", comment: ""), (typeString))
                titleLabel.text = warningMessage
            }
            
            let message = "deletion.warning.subtitle".localized
            subtitleLabel.text = message
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func getContentTypeString() ->String?{
        var typeString : String? = nil
        if source == .chats{
            typeString = (batchState == .single) ? NSLocalizedString("storage.management.selected.chat.media", comment: "") : (NSLocalizedString("storage.management.chat.media", comment: ""))
        }
        else if batchState == .single && source == .podcasts{
            typeString = NSLocalizedString("storage.management.this.podcast", comment: "")
        }
        else if let type = type{
            switch type {
            case .audio:
                typeString = NSLocalizedString("storage.management.audio.files", comment: "")
                break
            case .video:
                typeString = NSLocalizedString("storage.management.video", comment: "")
                break
            case .photo:
                typeString = NSLocalizedString("storage.management.images", comment: "")
                break
            case .file:
                typeString = NSLocalizedString("storage.management.files", comment: "")
                break
            }
        }
        return typeString
    }
    
    func moveToAwaitingApproval(){
        
        gotItButton.isHidden = true
        cancelButton.isHidden = false
        deletionButton.isHidden = false
        deletionSymbol.image = #imageLiteral(resourceName: "delete_can")
        imageViewWidth.constant = 35
        subtitleToTitleConstraintSpacing.constant = 14
        subtitleLeading.constant = 16
        viewBottomConstraint.constant = 40
        
        
        loadingCircularProgressView.stopRotation()
        self.loadingCircularProgressView.isHidden = true
        loadingCircularProgressView.setProgressStrokeColor(color: .clear)
        
        layoutIfNeeded()
        
        self.deletionSymbolContainerView.isHidden = false
        self.deletionSymbolContainerView.backgroundColor = UIColor.Sphinx.PrimaryRed
        let typeSnapshot = type
        self.type = typeSnapshot
    }
    
    func moveToLoadingUI(){
        self.loadingCircularProgressView.backgroundColor = .clear
        self.deletionButton.isHidden = true
        self.cancelButton.isHidden = true
        //self.deletionSymbol.image = #imageLiteral(resourceName: "deletion_loading")
        self.deletionSymbolContainerView.backgroundColor = .clear
        UIView.animate(withDuration: 0.05, delay: 0.0, animations: {
            self.loadingCircularProgressView.isHidden = false
            self.deletionSymbol.tintColor = UIColor.Sphinx.BodyInverted
            self.titleLabel.text = "storage.management.loading.deletion".localized
            self.subtitleLabel.text = "storage.management.loading.deletion.subtitle".localized
            self.viewBottomConstraint.constant = 6
            self.subtitleToTitleConstraintSpacing.constant = -24.0
            self.layoutIfNeeded()
        },
        completion: { _ in
            self.startRotation()
            self.loadingCircularProgressView.isHidden = false
            self.loadingCircularProgressView.setProgressStrokeColor(color: UIColor.Sphinx.PrimaryRed)
            self.loadingCircularProgressView.progressAnimation(to: 0.9, active: true)
            self.loadingCircularProgressView.playPauseLabel.isHidden = true
        })
    }
    
    func moveToFinishedUI(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.finalizeFinishedUIAfterDelay()
        })
    }
    
    func finalizeFinishedUIAfterDelay(){
        loadingCircularProgressView.stopRotation()
        self.loadingCircularProgressView.isHidden = true
        loadingCircularProgressView.setProgressStrokeColor(color: .clear)
        
        self.deletionSymbol.image = #imageLiteral(resourceName: "deletion_success")
        viewBottomConstraint.constant = 40
        subtitleToTitleConstraintSpacing.constant += 18
        subtitleLeading.constant = 50.0
        imageViewWidth.constant = 68
        gotItButton.isHidden = false
        gotItButton.layer.borderWidth = cancelButton.layer.borderWidth
        gotItButton.layer.borderColor = UIColor.Sphinx.Text.cgColor
        gotItButton.layer.cornerRadius = gotItButton.frame.height/2.0
        layoutIfNeeded()
        if let source = source,
           source == .chats{
            let message = String(format: NSLocalizedString("storage.management.deletion.complete.title", comment: ""), "chat media").capitalized
            titleLabel.text = message
        }
        else if let typeString = getContentTypeString(){
            let message = String(format: NSLocalizedString("storage.management.deletion.complete.title", comment: ""), typeString).capitalized
            titleLabel.text = message
        }
        let subtitle = String(format: NSLocalizedString("storage.management.deletion.complete.subtitle", comment: ""), spaceFreedString)
        subtitleLabel.text = subtitle
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MediaDeletionConfirmationView", owner: self, options: nil)
        addSubview(contentView)
        self.backgroundColor = .clear
        deletionSymbolContainerView.makeCircular()
        deletionButton.layer.cornerRadius = deletionButton.frame.height/2.0
        cancelButton.layer.borderColor = UIColor.Sphinx.InputOutline1.cgColor
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.cornerRadius = cancelButton.frame.height/2.0
        contentView.layer.cornerRadius = 16.0
        loadingCircularProgressView.isHidden = true
    }
    
    func startRotation(){
        loadingCircularProgressView.startRotation()
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        self.state = .loading
        delegate?.mediaDeletionConfirmTapped()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        if let delegate = delegate{
            delegate.mediaDeletionCancelTapped()
            self.state = .awaitingApproval
        }
    }
    
    
}
