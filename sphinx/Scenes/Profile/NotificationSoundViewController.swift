//
//  NotificationSoundViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol NotificationSoundDelegate: class {
    func didUpdateSound()
}

class NotificationSoundViewController: UIViewController {
    
    weak var delegate: NotificationSoundDelegate?
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var soundsTableView: UITableView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var sounds : [NotificationSoundHelper.Sound] = []
    var selectedSoundFile = ""
    
    var notificationSoundHelper: NotificationSoundHelper!
    let audioPlayerHelper = SoundsPlayer()
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: self.view)
        }
    }
    
    static func instantiate(helper: NotificationSoundHelper, delegate: NotificationSoundDelegate?) -> NotificationSoundViewController {
        let viewController = StoryboardScene.Profile.notificationSoundViewController.instantiate()
        viewController.delegate = delegate
        viewController.notificationSoundHelper = helper
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView.addShadow(location: VerticalLocation.bottom, opacity: 0.2, radius: 2.0)
        
        confirmButton.layer.cornerRadius = confirmButton.frame.size.height / 2
        viewTitle.addTextSpacing(value: 2)
        
        configureTableView()
    }
    
    func configureTableView() {
        sounds = notificationSoundHelper.getSounds()
        
        soundsTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        soundsTableView.registerCell(NotificationSoundTableViewCell.self)
        soundsTableView.delegate = self
        soundsTableView.dataSource = self
        soundsTableView.reloadData()
    }
    
    @IBAction func backButtonTouched() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func confirmButtonTocuhed() {
        loading = true
        updateProfile()
    }
    
    func updateProfile() {
        let id = UserData.sharedInstance.getUserId()
        let file = notificationSoundHelper.getSelectedSound().file
        let parameters = ["notification_sound" : file as AnyObject]

        API.sharedInstance.updateUser(id: id, params: parameters, callback: { contact in
            let _ = UserContactsHelper.insertContact(contact: contact)

            self.delegate?.didUpdateSound()
            self.backButtonTouched()
        }, errorCallback: {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                self.backButtonTouched()
            })
        })
    }
}

extension NotificationSoundViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? NotificationSoundTableViewCell {
            let sound = sounds[indexPath.row]
            cell.configure(sound: sound)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sound = sounds[indexPath.row]
        audioPlayerHelper.playSound(name: sound.file)
        
        updateSound(index: indexPath.row)
        soundsTableView.reloadData()
    }
    
    func updateSound(index: Int) {
        notificationSoundHelper.updateSound(index: index)
        sounds = notificationSoundHelper.getSounds()
    }
}

extension NotificationSoundViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationSoundTableViewCell", for: indexPath) as! NotificationSoundTableViewCell
        return cell
    }
}
