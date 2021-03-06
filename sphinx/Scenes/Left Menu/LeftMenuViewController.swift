//
//  Library
//
//  Created by Tomas Timinskas on 09/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import KYDrawerController

class LeftMenuViewController: UIViewController {
    
    private var rootViewController : RootViewController!
    private var walletBalanceService = WalletBalanceService()

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var walletIcon: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var optionsTableView: UITableView!
    @IBOutlet weak var addSatsButton: UIButton!
    
    let buttonsCount = 2
    
    let menuOptions:[MenuOption] = [
        MenuOption(iconCharacter: "", optionTitle: "menu.dashboard".localized),
        MenuOption(iconCharacter: "", optionTitle: "menu.contacts".localized),
        MenuOption(iconCharacter: "", optionTitle: "menu.profile".localized)
    ]
    
    let kMenuRowHeight: CGFloat = 65
    let kButtonRowHeight: CGFloat = 75
    
    struct MenuOption {
        var iconCharacter = ""
        var optionTitle = ""
        
        init(iconCharacter: String, optionTitle: String) {
            self.iconCharacter = iconCharacter
            self.optionTitle = optionTitle
        }
    }
    
    static func instantiate(rootViewController : RootViewController) -> LeftMenuViewController {
        let viewController = StoryboardScene.LeftMenu.leftMenuViewController.instantiate()
        viewController.rootViewController = rootViewController
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletIcon.tintColorDidChange()
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2
        profileImageView.clipsToBounds = true
        
        addSatsButton.layer.cornerRadius = addSatsButton.frame.size.height / 2
        addSatsButton.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureProfile()
        configureTable()
        walletBalanceService.updateBalance(labels: [balanceLabel])
    }
    
    func configureProfile() {
        if let profile = UserContact.getOwner() {
            nameLabel.text = profile.nickname?.getNameStyleString() ?? "name.unknown".localized.uppercased()
            
            if let imageUrl = profile.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), !imageUrl.isEmpty {
                MediaLoader.asyncLoadImage(imageView: profileImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"), completion: { image in
                    self.profileImageView.image = image
                }, errorCompletion: { _ in })
            } else {
                profileImageView.image = UIImage(named: "profile_avatar")
            }
        }
    }
    
    func configureTable() {
        optionsTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        optionsTableView.reloadData()
    }
    
    func goToChatList() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let centerVC = appDelegate.getCurrentVC(), centerVC.isKind(of: ChatViewController.self) {
            centerVC.navigationController?.popViewController(animated: false)
        } else {
            let chatList = ChatListViewController.instantiate(rootViewController: rootViewController, delegate: self)
            goTo(vc: chatList)
        }
    }
    
    func goToSupport() {
        supportButtonTouched()
    }
    
    public func goTo(vc: UIViewController) {
        DispatchQueue.main.async {
            self.rootViewController.setCenterViewController(vc: vc)
            self.closeLeftMenu()
        }
    }
    
    @IBAction func supportButtonTouched() {
        let supportVC = SupportViewController.instantiate(rootViewController: rootViewController)
        
        DispatchQueue.main.async {
            self.rootViewController.presentViewController(vc: supportVC)
            self.closeLeftMenu()
        }
    }
    
    @IBAction func logoutButtonTouched() {
        closeLeftMenu()
        GroupsPinManager.sharedInstance.logout()
    }
    
    @IBAction func addSatsButtonTouched() {
        let addSatsVC = AddSatsViewController.instantiate(rootViewController: rootViewController)
        let navigationC = UINavigationController(rootViewController: addSatsVC)
        navigationC.setNavigationBarHidden(true, animated: false)
        navigationC.modalPresentationStyle = .overCurrentContext
        rootViewController.presentViewController(vc: navigationC)
        closeLeftMenu()
    }
}

extension LeftMenuViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= menuOptions.count {
            return kButtonRowHeight
        }
        return kMenuRowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? LeftMenuOptionTableViewCell {
            let option = menuOptions[indexPath.row]
            cell.configureCell(option: option)
        } else if let cell = cell as? LeftMenuAddFriendTableViewCell {
            if indexPath.row == getRowsCount() - buttonsCount {
                cell.configureForAddFriend()
            } else {
                cell.configureForCreateTribe()
            }
            cell.delegate = self
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = menuOptions[indexPath.row]
        
        switch (option.optionTitle) {
        case "menu.profile".localized:
            let profile = ProfileViewController.instantiate(rootViewController: rootViewController, delegate: self)
            goTo(vc: profile)
            break
        case "menu.contacts".localized:
            let addressBook = AddressBookViewController.instantiate(rootViewController: rootViewController)
            goTo(vc: addressBook)
            break
        case "menu.dashboard".localized:
            let chatList = ChatListViewController.instantiate(rootViewController: rootViewController, delegate: self)
            goTo(vc: chatList)
            break
        default:
            break
        }
    }
}

extension LeftMenuViewController : UITableViewDataSource {
    func getRowsCount() -> Int {
        return menuOptions.count + buttonsCount
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getRowsCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= menuOptions.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeftMenuAddFriendTableViewCell", for: indexPath) as! LeftMenuAddFriendTableViewCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LeftMenuOptionTableViewCell", for: indexPath) as! LeftMenuOptionTableViewCell
            return cell
        }
    }
}

extension LeftMenuViewController : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        closeLeftMenu()
        
        if let centerVC = rootViewController.getLastCenterViewController() {
            let addfriendVC = AddFriendViewController.instantiate(rootViewController: self.rootViewController)
            addfriendVC.delegate = centerVC as? NewContactVCDelegate
            present(vc: addfriendVC, in: centerVC)
        }
    }
    
    func didTouchCreateGroup() {
        closeLeftMenu()
        
        if let centerVC = rootViewController.getLastCenterViewController() {
            let delegate = centerVC as? NewContactVCDelegate
            let createTribeVC = NewPublicGroupViewController.instantiate(rootViewController: rootViewController, delegate: delegate)
            present(vc: createTribeVC, in: centerVC)
        }
    }
    
    func present(vc: UIViewController, in centerVC: UIViewController) {
        let newNC = UINavigationController(rootViewController: vc)
        newNC.isNavigationBarHidden = true
        centerVC.present(newNC, animated: true, completion: nil)
    }
}

extension LeftMenuViewController : MenuDelegate {
    func shouldOpenLeftMenu() {
        if let drawer = rootViewController?.getDrawer() {
            drawer.setDrawerState(.opened, animated: true)
        }
    }
    
    func closeLeftMenu() {
        if let drawer = rootViewController?.getDrawer() {
            drawer.setDrawerState(.closed, animated: true)
        }
    }
}

extension LeftMenuViewController : KYDrawerControllerDelegate {
    func drawerController(_ drawerController: KYDrawerController, didChangeState state: KYDrawerController.DrawerState) {}
}
