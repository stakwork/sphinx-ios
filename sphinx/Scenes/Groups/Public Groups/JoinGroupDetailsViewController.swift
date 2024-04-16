//
//  JoinGroupDetailsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class JoinGroupDetailsViewController: KeyboardEventsViewController {
    
    weak var delegate: NewContactVCDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDescriptionLabel: UILabel!
    @IBOutlet weak var priceContainer: UIView!
    @IBOutlet weak var joinPriceLabel: UILabel!
    @IBOutlet weak var messagePriceLabel: UILabel!
    @IBOutlet weak var amountToStakeLabel: UILabel!
    @IBOutlet weak var timeToStakeLabel: UILabel!
    @IBOutlet weak var joinGroupButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var loadingGroupContainer: UIView!
    @IBOutlet weak var loadingGroupWheel: UIActivityIndicatorView!
    @IBOutlet weak var joinTribeScrollView: UIScrollView!
    @IBOutlet weak var imageUploadContainer: UIView!
    @IBOutlet weak var imageUploadLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var imageUploadLabel: UILabel!
    @IBOutlet weak var tribeMemberInfoView: TribeMemberInfoView!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    
    let owner = UserContact.getOwner()
    let groupsManager = GroupsManager.sharedInstance
    var qrString: String! = nil
    var tribeInfo : GroupsManager.TribeInfo? = nil
    
    var isV2Tribe : Bool {
        return qrString.contains("action=tribeV2") && qrString.contains("pubkey=")
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var loadingGroup = false {
        didSet {
            loadingGroupContainer.alpha = loadingGroup ? 1.0 : 0.0
            LoadingWheelHelper.toggleLoadingWheel(loading: loadingGroup, loadingWheel: loadingGroupWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    var uploading = false {
        didSet {
            imageUploadContainer.alpha = uploading ? 1.0 : 0.0
            LoadingWheelHelper.toggleLoadingWheel(loading: uploading, loadingWheel: imageUploadLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }    
    
    
    static func instantiate(
        qrString: String,
        delegate: NewContactVCDelegate? = nil
    ) -> JoinGroupDetailsViewController {
        let viewController = StoryboardScene.Groups.joinGroupDetailsViewController.instantiate()
        viewController.qrString = qrString
        viewController.delegate = delegate

        return viewController
    }
    
    static func instantiate(
        delegate: NewContactVCDelegate? = nil
    ) -> JoinGroupDetailsViewController{
        let viewController = StoryboardScene.Groups.joinGroupDetailsViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.addTextSpacing(value: 2)
        
        priceContainer.layer.cornerRadius = 10
        priceContainer.layer.borderWidth = 1
        
        joinGroupButton.layer.cornerRadius = joinGroupButton.frame.size.height / 2
        
        LoadingWheelHelper.toggleLoadingWheel(loading: false, loadingWheel: imageUploadLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        
        tribeMemberInfoView.configureWith(
            vc: self,
            accessoryView: keyboardAccessoryView,
            alias: owner?.nickname,
            picture: owner?.getPhotoUrl(),
            shouldFixAlias: true
        )
        

        loadGroupDetails()
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            joinTribeScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }

    @objc override func keyboardWillHide(_ notification: Notification) {
        joinTribeScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func loadGroupDetails() {
        loadingGroup = true
        
         if(isV2Tribe),
           let pubkey = groupsManager.getV2Pubkey(qrString: qrString),
           let host = groupsManager.getV2Host(qrString: qrString){
             tribeInfo = GroupsManager.TribeInfo(ownerPubkey:pubkey, host: host,uuid: pubkey)
        }
        else{
            tribeInfo = groupsManager.getGroupInfo(query: qrString)
        }
        
        if let tribeInfo = tribeInfo {
            groupsManager.fetchTribeInfo(
                host: tribeInfo.host,
                uuid: tribeInfo.uuid,
                useSSL: !isV2Tribe,
                completion: { groupInfo in
                    self.completeDataAndShow(groupInfo: groupInfo)
                },
                errorCallback: {
                    self.showErrorAndDismiss()
                })
        } else {
            showErrorAndDismiss()
        }
    }
    
    func completeDataAndShow(groupInfo: JSON) {
        groupsManager.update(tribeInfo: &tribeInfo!, from: groupInfo)
        
        priceContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        
        groupNameLabel.text = tribeInfo?.name ?? ""
        groupDescriptionLabel.text = tribeInfo?.description ?? ""
        joinPriceLabel.text = "\(tribeInfo?.priceToJoin ?? 0)"
        messagePriceLabel.text = "\(tribeInfo?.pricePerMessage ?? 0)"
        amountToStakeLabel.text = "\(tribeInfo?.amountToStake ?? 0)"
        timeToStakeLabel.text = "\(tribeInfo?.timeToStake ?? 0)"
        
        groupImageView.contentMode = .scaleAspectFill
        groupImageView.layer.cornerRadius = groupImageView.frame.size.height / 2
        
        if let imageUrl = tribeInfo?.img?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: groupImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
        } else {
            groupImageView.image = UIImage(named: "profile_avatar")
        }
        
        loadingGroup = false
    }
    
    func showErrorAndDismiss() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
            self.closeButtonTouched()
        })
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true)
    }
    
    @IBAction func keyboardButtonTouched(_ sender: UIButton) {
        switch (sender.tag) {
        case 0:
            tribeMemberInfoView.shouldRevert()
        default:
            break
        }
        view.endEditing(true)
    }
    
    @IBAction func joinGroupButtonTouched() {
        loading = true
        
        tribeMemberInfoView.uploadImage(completion: { (name, image) in
            self.joinTribe(name: name, imageUrl: image)
        })
    }
    
    func joinTribe(name: String?, imageUrl: String?) {
        if isV2Tribe,
        let tribeInfo = tribeInfo{
            groupsManager.finalizeTribeJoin(tribeInfo: tribeInfo, qrString: qrString)
            self.closeButtonTouched()
        }
        else{
            guard let name = name, !name.isEmpty else {
                loading = false
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "alias.cannot.empty".localized)
                return
            }
            
            if let tribeInfo = tribeInfo {
                var params = groupsManager.getParamsFrom(tribe: tribeInfo)
                params["my_alias"] = name as AnyObject
                params["my_photo_url"] = (imageUrl ?? "") as AnyObject
                
                API.sharedInstance.joinTribe(params: params, callback: { chatJson in
                    if let chat = Chat.insertChat(chat: chatJson) {
                        chat.tribeInfo = tribeInfo
                        chat.pricePerMessage = NSDecimalNumber(floatLiteral: Double(tribeInfo.pricePerMessage ?? 0))
                        
                        
                        if let feedUrl = tribeInfo.feedUrl {
                            ContentFeed.fetchChatFeedContentInBackground(feedUrl: feedUrl, chatId: chat.id, completion: { feedId in
                                
                                if let feedId = feedId {
                                    chat.contentFeed = ContentFeed.getFeedById(feedId: feedId)
                                    chat.saveChat()
                                }
                                
                                self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: 2)
                                self.closeButtonTouched()
                            })
                        }
                    } else {
                        self.showErrorAndDismiss()
                    }
                }, errorCallback: {
                    self.showErrorAndDismiss()
                })
            } else {
                showErrorAndDismiss()
            }
        }
       
    }
}

extension JoinGroupDetailsViewController : TribeMemberInfoDelegate {
    func didUpdateUploadProgress(uploadString: String) {
        uploading = true
        imageUploadLabel.text = uploadString
    }
}
