//
//  StoryboardScene
//
//  Created by Tomas Timinskas on 08/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import UIKit

internal enum StoryboardScene {
    
    internal enum Root: StoryboardType {
        internal static let storyboardName = "Root"
        
        internal static let initialScene = InitialSceneType<RootViewController>(storyboard: Root.self)
    }
    
    internal enum Pin: StoryboardType {
        internal static let storyboardName = "Pin"
        
        internal static let pinCodeViewController = SceneType<PinCodeViewController>(storyboard: Pin.self, identifier: "PinCodeViewController")
        
        internal static let setPinCodeViewController = SceneType<SetPinCodeViewController>(storyboard: Pin.self, identifier: "SetPinCodeViewController")
    }
    
    internal enum Chat: StoryboardType {
        internal static let storyboardName = "Chat"
        internal static let chatViewController = SceneType<ChatViewController>(storyboard: Chat.self, identifier: "ChatViewController")

        internal static let chatListViewController = SceneType<ChatListViewController>(storyboard: Chat.self, identifier: "ChatListViewController")

        internal static let createInvoiceViewController = SceneType<CreateInvoiceViewController>(storyboard: Chat.self, identifier: "CreateInvoiceViewController")

        internal static let payInvoiceViewController = SceneType<PayInvoiceViewController>(storyboard: Chat.self, identifier: "PayInvoiceViewController")
        
        internal static let chatAttachmentViewController = SceneType<ChatAttachmentViewController>(storyboard: Chat.self, identifier: "ChatAttachmentViewController")
        
        internal static let attachmentPriceViewController = SceneType<AttachmentPriceViewController>(storyboard: Chat.self, identifier: "AttachmentPriceViewController")
        
        internal static let imageFullScreenViewController = SceneType<ImageFullScreenViewController>(storyboard: Chat.self, identifier: "ImageFullScreenViewController")
        
        internal static let avViewController = SceneType<AVViewController>(storyboard: Chat.self, identifier: "AVViewController")
        
        internal static let paymentTemplateViewController = SceneType<PaymentTemplateViewController>(storyboard: Chat.self, identifier: "PaymentTemplateViewController")
        
        internal static let messageOptionsViewController = SceneType<MessageOptionsViewController>(storyboard: Chat.self, identifier: "MessageOptionsViewController")
        
        internal static let paidMessagePreviewViewController = SceneType<PaidMessagePreviewViewController>(storyboard: Chat.self, identifier: "PaidMessagePreviewViewController")
    }
    
    internal enum LeftMenu: StoryboardType {
        internal static let storyboardName = "LeftMenu"
        
        internal static let leftMenuViewController = SceneType<LeftMenuViewController>(storyboard: LeftMenu.self, identifier: "LeftMenuViewController")
        
        internal static let supportViewController = SceneType<SupportViewController>(storyboard: LeftMenu.self, identifier: "SupportViewController")
        
        internal static let addSatsAppViewController = SceneType<AddSatsAppViewController>(storyboard: LeftMenu.self, identifier: "AddSatsAppViewController")
        
        internal static let addSatsViewController = SceneType<AddSatsViewController>(storyboard: LeftMenu.self, identifier: "AddSatsViewController")
    }
    
    internal enum QRCodeScanner: StoryboardType {
        internal static let storyboardName = "QRCodeScanner"
        
        internal static let newQrCodeScannerViewController = SceneType<NewQRScannerViewController>(storyboard: QRCodeScanner.self, identifier: "NewQRScannerViewController")
    }
    
    internal enum History: StoryboardType {
        internal static let storyboardName = "History"
        
        internal static let historyViewController = SceneType<HistoryViewController>(storyboard: History.self, identifier: "HistoryViewController")
    }
    
    internal enum Profile: StoryboardType {
        internal static let storyboardName = "Profile"
        
        internal static let profileViewController = SceneType<ProfileViewController>(storyboard: Profile.self, identifier: "ProfileViewController")
        
        internal static let notificationSoundViewController = SceneType<NotificationSoundViewController>(storyboard: Profile.self, identifier: "NotificationSoundViewController")
    }
    
    internal enum Invite: StoryboardType {
        internal static let storyboardName = "Invite"
        
        internal static let inviteCodeViewController = SceneType<InviteCodeViewController>(storyboard: Invite.self, identifier: "InviteCodeViewController")
        
        internal static let inviteWelcomeViewController = SceneType<InviteWelcomeViewController>(storyboard: Invite.self, identifier: "InviteWelcomeViewController")
        
        internal static let setProfileImageViewController = SceneType<SetProfileImageViewController>(storyboard: Invite.self, identifier: "SetProfileImageViewController")
        
        internal static let setNickNameViewController = SceneType<SetNickNameViewController>(storyboard: Invite.self, identifier: "SetNickNameViewController")
        
        internal static let sphinxReadyViewController = SceneType<SphinxReadyViewController>(storyboard: Invite.self, identifier: "SphinxReadyViewController")
        
        internal static let addFriendViewController = SceneType<AddFriendViewController>(storyboard: Invite.self, identifier: "AddFriendViewController")
        
        internal static let confirmAddFriendViewController = SceneType<ConfirmAddFriendViewController>(storyboard: Invite.self, identifier: "ConfirmAddFriendViewController")
        
        internal static let shareInviteCodeViewController = SceneType<ShareInviteCodeViewController>(storyboard: Invite.self, identifier: "ShareInviteCodeViewController")
        
        internal static let keychainRestoreViewController = SceneType<KeychainRestoreViewController>(storyboard: Invite.self, identifier: "KeychainRestoreViewController")
    }
    
    internal enum Contacts: StoryboardType {
        internal static let storyboardName = "Contacts"
        
        internal static let newContactViewController = SceneType<NewContactViewController>(storyboard: Contacts.self, identifier: "NewContactViewController")
        
        internal static let addressBookViewController = SceneType<AddressBookViewController>(storyboard: Contacts.self, identifier: "AddressBookViewController")
    }
    
    internal enum QRCodeDetail: StoryboardType {
        internal static let storyboardName = "QRCodeDetail"
        
        internal static let qrCodeDetailViewController = SceneType<QRCodeDetailViewController>(storyboard: QRCodeDetail.self, identifier: "QRCodeDetailViewController")
        
        internal static let createInvoiceDetailsViewController = SceneType<CreateInvoiceDetailsViewController>(storyboard: QRCodeDetail.self, identifier: "CreateInvoiceDetailsViewController")
    }
    
    internal enum Subscription: StoryboardType {
        internal static let storyboardName = "Subscription"
        
        internal static let subscriptionFormViewController = SceneType<SubscriptionFormViewController>(storyboard: Subscription.self, identifier: "SubscriptionFormViewController")
        
        internal static let subscriptionDeatilsViewController = SceneType<SubscriptionDetailsViewController>(storyboard: Subscription.self, identifier: "SubscriptionDetailsViewController")
    }
    
    internal enum Groups: StoryboardType {
        internal static let storyboardName = "Groups"
        
        internal static let groupNameViewController = SceneType<GroupNameViewController>(storyboard: Groups.self, identifier: "GroupNameViewController")
        
        internal static let groupContactsViewController = SceneType<GroupContactsViewController>(storyboard: Groups.self, identifier: "GroupContactsViewController")
        
        internal static let groupDetailsViewController = SceneType<GroupDetailsViewController>(storyboard: Groups.self, identifier: "GroupDetailsViewController")
        
        internal static let groupPaymentViewController = SceneType<GroupPaymentViewController>(storyboard: Groups.self, identifier: "GroupPaymentViewController")
        
        internal static let joinGroupDetailsViewController = SceneType<JoinGroupDetailsViewController>(storyboard: Groups.self, identifier: "JoinGroupDetailsViewController")
        
        internal static let newPublicGroupViewController = SceneType<NewPublicGroupViewController>(storyboard: Groups.self, identifier: "NewPublicGroupViewController")
        
        internal static let groupTagsViewController = SceneType<GroupTagsViewController>(storyboard: Groups.self, identifier: "GroupTagsViewController")
    }
    
    internal enum Stakwork: StoryboardType {
        
        internal static let storyboardName = "Stakwork"
        
        internal static let stakworkAuthorizeViewController = SceneType<StakworkAuthorizeViewController>(storyboard: Stakwork.self, identifier: "StakworkAuthorizeViewController")
    }
    
    internal enum WebApps: StoryboardType {
        internal static let storyboardName = "WebApps"
        
        internal static let webAppViewController = SceneType<WebAppViewController>(storyboard: WebApps.self, identifier: "WebAppViewController")
        
        internal static let newPodcastPlayerViewController = SceneType<NewPodcastPlayerViewController>(storyboard: WebApps.self, identifier: "NewPodcastPlayerViewController")
        
        internal static let podcastAnimationViewController = SceneType<PodcastAnimationViewController>(storyboard: WebApps.self, identifier: "PodcastAnimationViewController")
        
        internal static let pickerViewController = SceneType<PickerViewController>(storyboard: WebApps.self, identifier: "PickerViewController")
        
        internal static let podcastNewEpisodeViewController = SceneType<PodcastNewEpisodeViewController>(storyboard: WebApps.self, identifier: "PodcastNewEpisodeViewController")
    }
    
}

internal protocol StoryboardType {
  static var storyboardName: String { get }
}

internal extension StoryboardType {
  static var storyboard: UIStoryboard {
    let name = self.storyboardName
    return UIStoryboard(name: name, bundle: Bundle(for: BundleToken.self))
  }
}

internal struct SceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type
  internal let identifier: String

  internal func instantiate() -> T {
    let identifier = self.identifier
    guard let controller = storyboard.storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
      fatalError("ViewController '\(identifier)' is not of the expected class \(T.self).")
    }
    return controller
  }
}

internal struct InitialSceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type

  internal func instantiate() -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController() as? T else {
      fatalError("ViewController is not of the expected class \(T.self).")
    }
    return controller
  }
}

private final class BundleToken {}
