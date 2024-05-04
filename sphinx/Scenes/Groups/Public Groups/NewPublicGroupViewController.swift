//
//  NewPublicGroupViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class NewPublicGroupViewController: KeyboardEventsViewController, BackCameraVC {
    
    weak var delegate: NewContactVCDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var formScrollView: UIScrollView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var imageUrlTextField: UITextField!
    @IBOutlet weak var feedContentTypeButton: UIButton!
    @IBOutlet weak var feedContentTypeField: UITextField!
    @IBOutlet var formFields: [UITextField]!
    @IBOutlet weak var listOnTribesLabel: UILabel!
    @IBOutlet weak var listOnTribesSwitch: UISwitch!
    @IBOutlet weak var privateTribeSwitch: UISwitch!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var createGroupButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    @IBOutlet weak var uploadingContainer: UIView!
    @IBOutlet weak var uploadingWheel: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsCollectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tagsVCBack: UIView!
    @IBOutlet weak var tagsVCContainer: UIView!
    @IBOutlet weak var tagsVCContainerHeight: NSLayoutConstraint!
    var tagsVC : GroupTagsViewController!
    var tagsAddedDataSource : TagsAddedDataSource!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    var currentField : UITextField?
    var previousFieldValue : String?
    
    let groupsManager = GroupsManager.sharedInstance
    var imagePickerManager = ImagePickerManager.sharedInstance
    var shouldUploadImage = false
    
    var chat: Chat? = nil
    
    let kTagRowHeight: CGFloat = 50
    let kTagContainerMargin: CGFloat = 10
    
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    
    var currentTags : [String] = []
    
    public enum GroupFields: Int {
        case Name
        case Image
        case Description
        case PriceToJoin
        case PricePerMessage
        case AmountToStake
        case TimeToStake
        case AppUrl
        case SecondBrainUrl
        case FeedUrl
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var uploadingPhoto = false {
        didSet {
            uploadingContainer.alpha = uploadingPhoto ? 1.0 : 0.0
            LoadingWheelHelper.toggleLoadingWheel(loading: uploadingPhoto, loadingWheel: uploadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(delegate: NewContactVCDelegate?, chat: Chat? = nil) -> NewPublicGroupViewController {
        let viewController = StoryboardScene.Groups.newPublicGroupViewController.instantiate()
        viewController.delegate = delegate
        viewController.chat = chat

        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        updateTags() { }
    }

    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            formScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }

    @objc override func keyboardWillHide(_ notification: Notification) {
        formScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func prepareView() {
        groupsManager.resetNewGroupInfo()
        
        let editing = isEditing()
        closeButton.isHidden = editing
        backButton.isHidden = !editing

        titleLabel.text = (isEditing() ? "edit.public.group" : "new.public.group").localized
        titleLabel.addTextSpacing(value: 2)
        
        privateTribeSwitch.isOn = false
        privateTribeSwitch.onTintColor = UIColor.Sphinx.PrimaryBlue
        
        listOnTribesSwitch.onTintColor = UIColor.Sphinx.PrimaryBlue
        listOnTribesLabel.addLinkFor(link: "tribes.sphinx.chat")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
        listOnTribesLabel.addGestureRecognizer(tap)
        
        groupImageView.layer.cornerRadius = groupImageView.frame.size.height / 2
        createGroupButton.layer.cornerRadius = createGroupButton.frame.size.height / 2
        tagsVCContainer.layer.cornerRadius = 10
        
        tagsCollectionView.layer.cornerRadius = 10
        tagsCollectionView.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        tagsCollectionView.layer.borderWidth = 1
        tagsCollectionView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        configureFields()
        completeEditView()
    }
    
    @objc func labelTapped(gesture: UITapGestureRecognizer) {
        if let label = gesture.view as? UILabel, let text = label.text {
            if let range = label.getRangeFor(link: "tribes.sphinx.chat") {
                if gesture.didTapAttributedTextInLabel(label, inRange: range) {
                    let linkString = (text as NSString).substring(with: range).withProtocol(protocolString: "https")
                    UIApplication.shared.open(URL(string: linkString)!, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    func toggleConfirmButton() {
        createGroupButton.isHidden = !groupsManager.isGroupInfoValid()
    }
    
    func configureFields() {
        for field in formFields {
            field.delegate = self
            field.inputAccessoryView = keyboardAccessoryView
        }
    }
    
    func showErrorAlert() {
        loading = false
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    @IBAction func groupImageButtonTouched() {
        imagePickerManager.configurePicker(vc: self)
        imagePickerManager.showAlert(title: "group.image".localized, message: "select.option".localized, sourceView: groupImageView)
    }
    
    @IBAction func keyboardButtonTouched(_ sender: UIButton) {
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            break
        case KeyboardButtons.Cancel.rawValue:
            shouldRevertValue()
            break
        default:
            break
        }
        view.endEditing(true)
    }
    
    @IBAction func listOnTribesSwitchChanged(_ sender: UISwitch) {
        groupsManager.newGroupInfo.unlisted = !sender.isOn
    }
    
    @IBAction func privateTribeSwitchChanged(_ sender: UISwitch) {
        groupsManager.newGroupInfo.privateTribe = sender.isOn
    }
    
    @IBAction func dismissTagsButtonTouched() {
//        hideTagsVC()
    }
    
    @IBAction func createGroupButtonTouched() {
        uploadImage()
    }
    
    @IBAction func feedContentTypeButtonTouched() {
        showFeedContentTypePicker()
    }
    
    @IBAction func backButtonTouched() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeButtonTouched() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
