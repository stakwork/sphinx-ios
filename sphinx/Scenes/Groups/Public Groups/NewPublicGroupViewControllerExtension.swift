//
//  NewPublicGroupViewControllerExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

extension NewPublicGroupViewController {
    
    func setTagsVCHeight() {
        let tagsContainerHeigh = (CGFloat(groupsManager.newGroupInfo.tags.count) * kTagRowHeight) + kTagContainerMargin + kTagRowHeight
        if tagsVCContainerHeight.constant != tagsContainerHeigh {
            tagsVCContainerHeight.constant = tagsContainerHeigh
            tagsVCContainer.layoutIfNeeded()
        }
    }
    
    func showTagsVC() {
        let discoverVC = DiscoverTribesTagSelectionVC.instantiate()
        discoverVC.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(discoverVC, animated: false)
        
        discoverVC.discoverTribeTagSelectionVM.selectedTags = currentTags
        discoverVC.delegate = self
    }
    
    func toggleTagsVCView(show: Bool, completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0.3, animations: {
            self.tagsVCBack.alpha = show ? 1.0 : 0.0
        }, completion: { _ in
            completion()
        })
    }
    
    func updateTags(completion: @escaping () -> ()) {
        let previousTagsHeight = self.getCollectionViewHeight()
        tagsAddedDataSource = TagsAddedDataSource(collectionView: tagsCollectionView)
        tagsAddedDataSource.setTags(tags: groupsManager.newGroupInfo.tags)
        tagsAddedDataSource.addButtonTapped = showTagsVC
        tagsAddedDataSource.tagSelected = updateSelectedTags
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            self.tagsCollectionHeightConstraint.constant = self.getCollectionViewHeight()
            self.scrollViewContentHeight.constant = self.scrollViewContentHeight.constant + (self.getCollectionViewHeight() - previousTagsHeight)
            self.view.layoutIfNeeded()
            completion()
        })
    }
    
    func updateSelectedTags(index: Int) {
        groupsManager.newGroupInfo.tags.remove(at: index)
        currentTags.remove(at: index)
        updateTags { }
    }
    
    func getCollectionViewHeight() -> CGFloat {
        return tagsCollectionView.contentSize.height + tagsCollectionView.contentInset.bottom + tagsCollectionView.contentInset.top
    }
    
    func completeEditView() {
        if let chat = chat {
            formScrollView.alpha = 0.0
            
            if let chatTribeInfo = chat.tribeInfo {
                groupsManager.newGroupInfo = chatTribeInfo
                
                for field in formFields {
                    switch(field.tag) {
                    case GroupFields.Name.rawValue:
                        field.text = chatTribeInfo.name ?? ""
                        break
                    case GroupFields.Description.rawValue:
                        field.text = chatTribeInfo.description ?? ""
                        break
                    case GroupFields.Image.rawValue:
                        field.text = chatTribeInfo.img ?? ""
                        completeUrlAndLoadImage(textField: field)
                        break
                    case GroupFields.PriceToJoin.rawValue:
                        let priceToJoin = chatTribeInfo.priceToJoin ?? 0
                        field.text = priceToJoin > 0 ? "\(priceToJoin)" : ""
                        break
                    case GroupFields.PricePerMessage.rawValue:
                        let pricePerMessage = chatTribeInfo.pricePerMessage ?? 0
                        field.text = pricePerMessage > 0 ? "\(pricePerMessage)" : ""
                        break
                    case GroupFields.AmountToStake.rawValue:
                        let amountToStake = chatTribeInfo.amountToStake ?? 0
                        field.text = amountToStake > 0 ? "\(amountToStake)" : ""
                        break
                    case GroupFields.TimeToStake.rawValue:
                        let timeToStake = chatTribeInfo.timeToStake ?? 0
                        field.text = timeToStake > 0 ? "\(timeToStake)" : ""
                        break
                    case GroupFields.AppUrl.rawValue:
                        field.text = chatTribeInfo.appUrl ?? ""
                        break
                    case GroupFields.SecondBrainUrl.rawValue:
                        field.text = chatTribeInfo.secondBrainUrl ?? ""
                        break
                    case GroupFields.FeedUrl.rawValue:
                        field.text = chatTribeInfo.feedUrl ?? ""
                        break
                    default:
                        break
                    }
                }
                
                
                let feedUrl = chatTribeInfo.feedUrl ?? ""
                let feedType = (chatTribeInfo.feedContentType ?? FeedContentType.defaultValue).description
                feedContentTypeField.text = (feedUrl.isEmpty) ? "" : feedType
                feedContentTypeButton.isUserInteractionEnabled = !feedUrl.isEmpty
                
                listOnTribesSwitch.isOn = !chatTribeInfo.unlisted
                privateTribeSwitch.isOn = chatTribeInfo.privateTribe
                
                updateTags(){
                    self.createGroupButton.setTitle("save.upper".localized, for: .normal)
                    self.toggleConfirmButton()
                    self.formScrollView.alpha = 1.0
                }
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                    self.backButtonTouched()
                })
            }
        }
    }
    
    func isEditing() -> Bool {
        return chat?.id != nil
    }
    
    func editOrCreateGroup() {
        uploadingPhoto = false
        loading = true
        
        let params = groupsManager.getNewGroupParams()
        
        if isEditing() {
            editGroup(id: chat!.id, params: params)
            return
        }
        createGroup(params: params)
    }
    
    func mapChatJSON(rawTribeJSON:[String:Any])->JSON?{
        guard let name = rawTribeJSON["name"] as? String,
              let ownerPubkey = rawTribeJSON["pubkey"] as? String,
              ownerPubkey.isPubKey else{
            self.showErrorAlert()
            return nil
          }
        var chatDict = rawTribeJSON
        
        let mappedFields : [String:Any] = [
            "id":CrypterManager.sharedInstance.generateCryptographicallySecureRandomInt(upperBound: Int(1e5)),
            "owner_pubkey": ownerPubkey,
            "name" : name,
            "is_tribe_i_created":true,
            "type":Chat.ChatType.publicGroup.rawValue
            //"created_at":createdAt
        ]
        
        for key in mappedFields.keys{
            chatDict[key] = mappedFields[key]
        }
        
        let chatJSON = JSON(chatDict)
        return chatJSON
    }
    
    func createGroup(params: [String: AnyObject]) {
        guard let name = params["name"] as? String,
            let description = params["description"] as? String else{
            //Send Alert?
            self.showErrorAlert()
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewTribeNotification(_:)), name: .newTribeCreationComplete, object: nil)
        SphinxOnionManager.sharedInstance.createTribe(params:params)
    }
    

    @objc func handleNewTribeNotification(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .newTribeCreationComplete, object: nil)
        if let tribeJSONString = notification.userInfo?["tribeJSON"] as? String,
           let tribeJSON = try? tribeJSONString.toDictionary(),
           let chatJSON = mapChatJSON(rawTribeJSON: tribeJSON),
           let chat = Chat.insertChat(chat: chatJSON)
        {
            chat.managedObjectContext?.saveContext()
            self.shouldDismissView()
            return
        }
        showErrorAlert()
    }
    
    func editGroup(id: Int, params: [String: AnyObject]) {
        API.sharedInstance.editGroup(id: id, params: params, callback: { chatJson in
            if let chat = Chat.insertChat(chat: chatJson) {
                chat.tribeInfo = self.groupsManager.newGroupInfo
                self.shouldDismissView(chat: chat)
            } else {
                self.showErrorAlert()
            }
        }, errorCallback: {
            self.showErrorAlert()
        })
    }
    
    func shouldDismissView(chat: Chat? = nil) {
        if let chat = chat {
            self.delegate?.shouldReloadChat?(chat: chat)
            self.navigationController?.popViewController(animated: true)
        } else {
            self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: -1)
            self.dismiss(animated: true)
        }
    }
    
    func showFeedContentTypePicker() {
        let values = FeedContentType.allCases.map { $0.description }
        let selectedValue = FeedContentType.allCases.filter { $0.description == feedContentTypeField.text}.first?.description ?? values.first?.description
        
        let pickerVC = PickerViewController.instantiate(
            values: values,
            selectedValue: selectedValue ?? "",
            title: "picker-title.tribe-form.feed-type".localized,
            delegate: self
        )
        
        self.present(pickerVC, animated: false, completion: nil)
    }
}

extension NewPublicGroupViewController : PickerViewDelegate {
    func didSelectValue(value: String) {
        let selectedValue = FeedContentType.allCases.filter { $0.description == value}.first
        
        feedContentTypeField.text = selectedValue?.description ?? "-"
        groupsManager.newGroupInfo.feedContentType = selectedValue
        
        toggleConfirmButton()
    }
}

extension NewPublicGroupViewController : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        completeValue(textField: textField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentField = textField
        previousFieldValue = textField.text
    }
    
    func shouldRevertValue() {
        if let currentField = currentField, let previousFieldValue = previousFieldValue {
            currentField.text = previousFieldValue
        }
    }
    
    func completeValue(textField: UITextField) {
        switch (textField.tag) {
        case GroupFields.Name.rawValue:
            groupsManager.newGroupInfo.name = textField.text ?? ""
            break
        case GroupFields.Image.rawValue:
            completeUrlAndLoadImage(textField: textField)
            break
        case GroupFields.Description.rawValue:
            groupsManager.newGroupInfo.description = textField.text ?? ""
            break
        case GroupFields.PriceToJoin.rawValue:
            groupsManager.newGroupInfo.priceToJoin = Int(textField.text ?? "")
            break
        case GroupFields.PricePerMessage.rawValue:
            groupsManager.newGroupInfo.pricePerMessage = Int(textField.text ?? "")
        case GroupFields.AmountToStake.rawValue:
            groupsManager.newGroupInfo.amountToStake = Int(textField.text ?? "")
        case GroupFields.TimeToStake.rawValue:
            groupsManager.newGroupInfo.timeToStake = Int(textField.text ?? "")
        case GroupFields.AppUrl.rawValue:
            if let url = textField.text, url.isValidURL || url.isEmpty {
                groupsManager.newGroupInfo.appUrl = textField.text ?? ""
            } else {
                invalidUrl()
            }
            break
        case GroupFields.SecondBrainUrl.rawValue:
            if let url = textField.text, url.isValidURL || url.isEmpty {
                groupsManager.newGroupInfo.secondBrainUrl = textField.text ?? ""
            } else {
                invalidUrl()
            }
            break
        case GroupFields.FeedUrl.rawValue:
            if let url = textField.text {
                if url.isValidURL || url.isEmpty {
                    groupsManager.newGroupInfo.feedUrl = textField.text ?? ""
                } else {
                    invalidUrl()
                }
                validateFeedUrl(url)
            }
            break
        default:
            break
        }
        
        toggleConfirmButton()
    }
    
    func invalidUrl() {
        newMessageBubbleHelper.showGenericMessageView(
            text: "invalid.url".localized,
            textColor: UIColor.white,
            backColor: UIColor.Sphinx.BadgeRed,
            backAlpha: 1.0
        )
        shouldRevertValue()
    }
    
    func validateFeedUrl(_ url: String) {
        let validUrl = url.isValidURL
        feedContentTypeButton.isUserInteractionEnabled = validUrl
        feedContentTypeField.text = validUrl ? feedContentTypeField.text : ""
        if (validUrl) { showFeedContentTypePicker()}
    }
    
    func completeUrlAndLoadImage(textField: UITextField) {
        let imgUrl = textField.text ?? ""
        
        if imgUrl.isValidURL {
            groupsManager.newGroupInfo.img = imgUrl
            
            if let nsUrl = URL(string: imgUrl) {
                showImage(url: nsUrl, contentMode: .scaleAspectFill)
            }
        } else if groupImageView.image == nil {
            showImage(image: UIImage(named: "profileImageIcon"), contentMode: .center)
            textField.text = ""
        }
    }
    
    func showImage(image: UIImage? = nil, url: URL? = nil, contentMode: UIView.ContentMode) {
        shouldUploadImage = false
        
        if let image = image {
            groupImageView.image = image
        } else if let url = url {
            MediaLoader.asyncLoadImage(imageView: groupImageView, nsUrl: url, placeHolderImage: UIImage(named: "profileImageIcon"))
        }
        groupImageView.contentMode = contentMode
    }
}

extension NewPublicGroupViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            picker.dismiss(animated:true, completion: {
                self.showImage(image: chosenImage, contentMode: .scaleAspectFill)
                self.shouldUploadImage = true
                self.imageUrlTextField.text = ""
            })
        }
    }
    
    func uploadImage() {
        if let image = groupImageView.image, let imgData = image.jpegData(compressionQuality: 0.5), shouldUploadImage {
            uploadingPhoto = true
            
            let attachmentsManager = AttachmentsManager.sharedInstance
            attachmentsManager.setDelegate(delegate: self)
            
            let attachmentObject = AttachmentObject(data: imgData, type: AttachmentsManager.AttachmentType.Photo)
            attachmentsManager.uploadImage(attachmentObject: attachmentObject, route: "public")
        } else {
            editOrCreateGroup()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension NewPublicGroupViewController : AttachmentsManagerDelegate {
    func didSuccessUploadingImage(url: String) {
        chat?.image = nil
        groupsManager.newGroupInfo.img = url
        imageUrlTextField.text = url
        editOrCreateGroup()
    }
}

extension NewPublicGroupViewController : DiscoverTribesTagSelectionDelegate {
    func didSelect(selections: [String]) {
        
        let newSet = Set(selections)
        let oldSet = Set(currentTags)
        
        if (newSet != oldSet) {
            
            self.currentTags = selections
            
            groupsManager.newGroupInfo.tags = getSelectedTags(currentTags: currentTags)
            updateTags{ }
        }
    }
    
    func getSelectedTags(currentTags: [String]) -> [GroupsManager.Tag] {
        let tagDictionary = [
            "Bitcoin": GroupsManager.Tag(image: "bitcoinTagIcon", description: "Bitcoin", selected: true),
            "Lightning": GroupsManager.Tag(image: "lightningTagIcon", description: "Lightning", selected: true),
            "NSFW": GroupsManager.Tag(image: "sphinxTagIcon", description: "NSFW", selected: true),
            "Crypto": GroupsManager.Tag(image: "cryptoTagIcon", description: "Crypto", selected: true),
            "Tech": GroupsManager.Tag(image: "techTagIcon", description: "Tech", selected: true),
            "Altcoins": GroupsManager.Tag(image: "altcoinsTagIcon", description: "Altcoins", selected: true),
            "Music": GroupsManager.Tag(image: "musicTagIcon", description: "Music", selected: true),
            "Podcast": GroupsManager.Tag(image: "podcastTagIcon", description: "Podcast", selected: true)
        ]
        
        return currentTags.map({tagDictionary[$0] ?? GroupsManager.Tag(image: "bitcoinTagIcon", description: "Bitcoin")})
    }
}
