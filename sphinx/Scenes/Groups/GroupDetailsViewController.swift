//
//  GroupDetailsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol GroupDetailsDelegate: class {
    func shouldReloadMessage(message: TransactionMessage)
}

class GroupDetailsViewController: UIViewController {
    weak var delegate: GroupDetailsDelegate?

    @IBOutlet weak var membersTableView: UITableView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupNameTop: NSLayoutConstraint!
    @IBOutlet weak var groupDateLabel: UILabel!
    @IBOutlet weak var groupPriceLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var groupOptionsButton: UIButton!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var tribeMemberInfoContainer: UIView!
    @IBOutlet weak var tribeMemberInfoView: TribeMemberInfoView!
    @IBOutlet weak var tribeMemberInfoContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var imageUploadContainer: UIView!
    @IBOutlet weak var imageUploadLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var imageUploadLabel: UILabel!
    @IBOutlet weak var tribeBadgesLabel: UILabel!
    @IBOutlet weak var groupPinContainer: GroupPinView!
    
    @IBOutlet weak var badgeManagementContainerView: UIView!
    @IBOutlet weak var badgeManagementContainerHeight : NSLayoutConstraint!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    var tableDataSource : GroupMembersDataSource!
    
    let kGroupNameTop: CGFloat = 31
    let kGroupNameWithPricesTop: CGFloat = 23
    
    
    var chat: Chat!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    var uploading = false {
        didSet {
            imageUploadContainer.alpha = uploading ? 1.0 : 0.0
            LoadingWheelHelper.toggleLoadingWheel(loading: uploading, loadingWheel: imageUploadLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(chat: Chat, delegate: GroupDetailsDelegate? = nil) -> GroupDetailsViewController {
        let viewController = StoryboardScene.Groups.groupDetailsViewController.instantiate()
        viewController.chat = chat
        viewController.delegate = delegate
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTitle.text = (chat.isPublicGroup() ? "tribe.details" : "group.details").localized
        tribeBadgesLabel.text = "badges.tribe-badges".localized
        
        loadData()
    }
    
    func loadData() {
        membersTableView.alpha = chat.isPrivateGroup() || chat.isMyPublicGroup() ? 1.0 : 0.0
        
        setGroupInfo()
        configureTableView()
    }
    
    func setGroupInfo() {
        groupImageView.layer.cornerRadius = groupImageView.frame.size.height / 2
        groupImageView.clipsToBounds = true
        
        groupPinContainer.configureWith(chat: chat)
        
        if let urlString = chat.photoUrl, let nsUrl = URL(string: urlString) {
            MediaLoader.asyncLoadImage(imageView: groupImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
        } else {
            groupImageView.image = UIImage(named: "profile_avatar")
        }
        
        groupNameLabel.text = chat.name ?? "unknown.group".localized
        
        let createdOn = String(format: "created.on".localized, chat.createdAt.getStringDate(format: "EEE MMM dd HH:mm"))
        groupDateLabel.text = createdOn
        
        updateTribePrices()
        configureTribeMemberView()
        configureBadgeManagementView()
    }
    
    func updateTribePrices() {
        if chat?.isPublicGroup() ?? false {
            if let prices = chat?.getTribePrices() {
                self.groupPriceLabel.text = String(format: "group.price.text".localized, "\(prices.0)", "\(prices.1)")
                self.groupNameTop.constant = self.kGroupNameWithPricesTop
            }
        }
    }
    
    func configureTribeMemberView() {
        if let chat = chat, let owner = UserContact.getOwner(), chat.isPublicGroup() {
            let alias = chat.myAlias ?? owner.nickname
            let photoUrl = chat.myPhotoUrl ?? owner.getPhotoUrl()
            
            tribeMemberInfoContainerHeight.constant = 160
            
            tribeMemberInfoView.configureWith(
                vc: self,
                accessoryView: keyboardAccessoryView,
                alias: alias,
                picture: photoUrl
            )
            
            tribeMemberInfoContainer.isHidden = false
        }
    }
    
    func configureBadgeManagementView(){
        if let chat = chat,
           chat.isMyPublicGroup(){
            badgeManagementContainerView.backgroundColor = UIColor.Sphinx.Body
            badgeManagementContainerHeight.constant = 90
            badgeManagementContainerView.isHidden = false
            badgeManagementContainerView.isUserInteractionEnabled = true
            badgeManagementContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBadgeManagementView)))
        }
    }
    
    @objc func didTapBadgeManagementView(){
        let badgeManagementVC = BadgeAdminManagementListVC.instantiate(chatID: chat.id)
        self.navigationController?.pushViewController(badgeManagementVC, animated: true)
    }
    
    func configureTableView() {
        membersTableView.registerCell(GroupContactTableViewCell.self)
        membersTableView.registerCell(GroupAddMemberTableViewCell.self)
        
        let title = (chat.isPublicGroup() ? "tribe.members.upper" : "group.members.upper").localized
        tableDataSource = GroupMembersDataSource(tableView: membersTableView, title: title)
        tableDataSource.groupDetailsDelegate = delegate
        tableDataSource.addMemberDelegate = self
        membersTableView.backgroundColor = UIColor.Sphinx.Body
        membersTableView.delegate = tableDataSource
        membersTableView.dataSource = tableDataSource
        membersTableView.contentInset.bottom = getWindowInsets().bottom
        tableDataSource.reloadContacts(chat: chat)
    }
    
    func showOptions() {
        let optionsLabel = (chat.isPublicGroup() ? "tribe.options" : "group.options").localized
        let alert = UIAlertController(title: optionsLabel, message: "select.option".localized, preferredStyle: .actionSheet)
        
        let isPublicGroup = chat.isPublicGroup()
        let isMyPublicGroup = chat.isMyPublicGroup()
        
        if isPublicGroup {
            alert.addAction(UIAlertAction(title: "notifications.level".localized, style: .default, handler:{ (UIAlertAction) in
                self.goToNotificationsLevel()
            }))
            if isMyPublicGroup {
                alert.addAction(UIAlertAction(title: "share.group".localized, style: .default, handler:{ (UIAlertAction) in
                    self.goToShare()
                }))
                
                alert.addAction(UIAlertAction(title: "edit.tribe".localized, style: .default, handler:{ (UIAlertAction) in
                    self.goToEditGroup()
                }))
                
                alert.addAction(UIAlertAction(title: "tribe.add-member".localized, style: .default, handler:{ (UIAlertAction) in
                    self.goToAddMember()
                }))
                
                alert.addAction(UIAlertAction(title: "delete.tribe".localized, style: .destructive, handler:{ (UIAlertAction) in
                    self.exitAndDeleteGroup()
                }))
            } else {
                if chat.removedFromGroup() {
                    alert.addAction(UIAlertAction(title: "delete.tribe".localized, style: .destructive, handler:{ (UIAlertAction) in
                        self.exitAndDeleteGroup()
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: "exit.tribe".localized, style: .destructive, handler:{ (UIAlertAction) in
                        self.exitAndDeleteGroup()
                    }))
                }
            }
        } else {
            alert.addAction(UIAlertAction(title: "exit.group".localized, style: .destructive, handler:{ (UIAlertAction) in
                self.exitAndDeleteGroup()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel ))
        alert.popoverPresentationController?.sourceView = groupOptionsButton
        alert.popoverPresentationController?.sourceRect = groupOptionsButton.bounds
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func goToEditGroup() {
        let createGroupVC = NewPublicGroupViewController.instantiate(delegate: self, chat: chat)
        self.navigationController?.pushViewController(createGroupVC, animated: true)
    }
    
    func goToShare() {
        if let link = chat.getJoinChatLink() {
            let qrCodeDetailViewModel = QRCodeDetailViewModel(qrCodeString: link, amount: 0, viewTitle: "share.group.link".localized)
            let viewController = QRCodeDetailViewController.instantiate(with: qrCodeDetailViewModel)
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    func goToAddMember() {
        let viewController = AddTribeMemberViewController.instantiate(with: chat, delegate: self)
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToNotificationsLevel() {
        let notificationsVC = NotificationsLevelViewController.instantiate(chatId: chat.id, delegate: nil)
        self.present(notificationsVC, animated: true, completion: nil)
    }
    
    func exitAndDeleteGroup() {
        let isPublicGroup = chat.isPublicGroup()
        let isMyPublicGroup = chat.isMyPublicGroup()
        let deleteLabel = (isPublicGroup ? "delete.tribe" : "delete.group").localized
        let confirmDeleteLabel = (isMyPublicGroup ? "confirm.delete.tribe" : (isPublicGroup ? "confirm.exit.delete.tribe" : "confirm.exit.delete.group")).localized
        
        AlertHelper.showTwoOptionsAlert(title: deleteLabel, message: confirmDeleteLabel, confirm: {
            self.loading = true
            SphinxOnionManager.sharedInstance.deleteTribe(tribeChat: self.chat)
            DispatchQueue.main.async{
                CoreDataManager.sharedManager.deleteChatObjectsFor(self.chat)
            }
            DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
                self.navigationController?.popToRootViewController(animated: true)
            })
        })
    }
    
    func uploadImage(image: UIImage) {
        let id = chat.id
        let fixedImage = image.fixedOrientation()
        loading = true
        
        API.sharedInstance.uploadImage(chatId: id, image: fixedImage, progressCallback: { progress in
            print("Progress: \(progress)")
        }, callback: { (success, fileUrl) in
            self.loading = false
            
            if let fileUrl = fileUrl, success {
                MediaLoader.storeImageInCache(img: image, url: fileUrl, message: nil)
                self.imageUploaded(photoUrl: fileUrl)
            } else {
                self.imageUploaded(photoUrl: nil)
            }
        })
    }
    
    func imageUploaded(photoUrl: String?) {
        if let photoUrl = photoUrl {
            chat.photoUrl = photoUrl
        }
    }
    
    func shouldDismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func groupDeleted() {
        navigationController?.popToRootViewController(animated: true)
//        let mainCoordinator = MainCoordinator(rootViewController: rootViewController)
//        mainCoordinator.presentInitialDrawer()
    }
    
    @IBAction func groupPictureButtonTouched() {
        let isPublicGroup = chat.isPublicGroup()
        if isPublicGroup { return }
        
        let imageLabel = (isPublicGroup ? "tribe.image" : "group.image").localized
        imagePickerManager.configurePicker(vc: self)
        imagePickerManager.showAlert(title: imageLabel, message: "select.option".localized, sourceView: groupImageView)
    }
    
    @IBAction func groupOptionsButtonTouched() {
        showOptions()
    }
    
    @IBAction func keyboardButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case 0:
            tribeMemberInfoView.shouldRevert()
        default:
            didChangeImageOrAlias()
        }
        view.endEditing(true)
    }
    
    @IBAction func backButtonTouched() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension GroupDetailsViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let fixedImage = chosenImage.fixedOrientation()
            self.groupImageView.image = fixedImage
            
            picker.dismiss(animated:true, completion: {
                self.uploadImage(image: fixedImage)
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension GroupDetailsViewController : AddTribeMemberDelegate {
    func shouldReloadMembers() {
        tableDataSource.reloadContacts(chat: chat)
    }
}

extension GroupDetailsViewController : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        let groupContactVC = GroupContactsViewController.instantiate(delegate: self, chat: chat)
        self.present(groupContactVC, animated: true, completion: nil)
    }
}

extension GroupDetailsViewController : NewContactVCDelegate {
    func shouldReloadChat(chat: Chat) {
        let chatListViewModel = ChatListViewModel()
        
        chatListViewModel.loadFriends { _ in
            self.chat = chat
            self.loadData()
        }
    }
}

extension GroupDetailsViewController : TribeMemberInfoDelegate {
    func didUpdateUploadProgress(uploadString: String) {
        uploading = true
        imageUploadLabel.text = uploadString
    }
    
    func didChangeImageOrAlias() {
        tribeMemberInfoView.uploadImage(completion: {(alias, photoUrl) in
            self.uploading = false
            self.updateChat(alias: alias, photoUrl: photoUrl)
        })
    }
    
    func updateChat(alias: String?, photoUrl: String?) {
        guard let alias = alias, !alias.isEmpty else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "alias.cannot.empty".localized)
            return
        }
        let params: [String: AnyObject] = ["my_alias" : alias as AnyObject, "my_photo_url": (photoUrl ?? "") as AnyObject]
        
        API.sharedInstance.updateChat(chatId: chat.id, params: params, callback: {
            self.chat.myAlias = alias
            self.chat.myPhotoUrl = photoUrl ?? self.chat.myPhotoUrl
        }, errorCallback: {})
    }
}
