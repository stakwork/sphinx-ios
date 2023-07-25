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

        internal static let createInvoiceViewController = SceneType<CreateInvoiceViewController>(storyboard: Chat.self, identifier: "CreateInvoiceViewController")

        internal static let payInvoiceViewController = SceneType<PayInvoiceViewController>(storyboard: Chat.self, identifier: "PayInvoiceViewController")
        
        internal static let chatAttachmentViewController = SceneType<ChatAttachmentViewController>(storyboard: Chat.self, identifier: "ChatAttachmentViewController")
        
        
        internal static let attachmentPriceViewController = SceneType<AttachmentPriceViewController>(storyboard: Chat.self, identifier: "AttachmentPriceViewController")
        
        internal static let attachmentFullScreenViewController = SceneType<AttachmentFullScreenViewController>(storyboard: Chat.self, identifier: "AttachmentFullScreenViewController")
        
        internal static let avViewController = SceneType<AVViewController>(storyboard: Chat.self, identifier: "AVViewController")
        
        internal static let paymentTemplateViewController = SceneType<PaymentTemplateViewController>(storyboard: Chat.self, identifier: "PaymentTemplateViewController")
        
        internal static let messageOptionsViewController = SceneType<MessageOptionsViewController>(storyboard: Chat.self, identifier: "MessageOptionsViewController")
        
        internal static let paidMessagePreviewViewController = SceneType<PaidMessagePreviewViewController>(storyboard: Chat.self, identifier: "PaidMessagePreviewViewController")
        
        internal static let tribeMemberPopupViewController = SceneType<TribeMemberPopupViewController>(storyboard: Chat.self, identifier: "TribeMemberPopupViewController")
        
        internal static let notificationsLevelViewController = SceneType<NotificationsLevelViewController>(storyboard: Chat.self, identifier: "NotificationsLevelViewController")
        
        internal static let tribeMemberProfileViewController = SceneType<TribeMemberProfileViewController>(storyboard: Chat.self, identifier: "TribeMemberProfileViewController")
        
        internal static let newChatViewController = SceneType<NewChatViewController>(storyboard: Chat.self, identifier: "NewChatViewController")

        internal static let pinMessageViewController = SceneType<PinMessageViewController>(storyboard: Chat.self, identifier: "PinMessageViewController")
        
        internal static let threadsListViewController = SceneType<ThreadsListViewController>(storyboard: Chat.self, identifier: "ThreadsListViewController")
    }
    
    internal enum Dashboard: StoryboardType {
        internal static let storyboardName = "Dashboard"
        
        internal static let dashboardRootViewController = SceneType<DashboardRootViewController>(storyboard: Dashboard.self, identifier: "DashboardRootViewController")
        
        
        internal static let feedsContainerViewController = SceneType<DashboardFeedsContainerViewController>(
            storyboard: Dashboard.self,
            identifier: "DashboardFeedsContainerViewController"
        )
        
        
        internal static let dashboardFeedsEmptyStateViewController = SceneType<DashboardFeedsEmptyStateViewController>(
            storyboard: Dashboard.self,
            identifier: "DashboardFeedsEmptyStateViewController"
        )
        
        
        internal static let allTribeFeedsCollectionViewController = SceneType<AllTribeFeedsCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "AllTribeFeedsCollectionViewController"
        )
        
        
        internal static let FeedSearchContainerViewController = SceneType<FeedSearchContainerViewController>(
            storyboard: Dashboard.self,
            identifier: "FeedSearchContainerViewController"
        )
        
        
        internal static let FeedSearchEmptyStateViewController = SceneType<FeedSearchEmptyStateViewController>(
            storyboard: Dashboard.self,
            identifier: "FeedSearchEmptyStateViewController"
        )
        
        
        internal static let FeedSearchResultsCollectionViewController = SceneType<FeedSearchResultsCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "FeedSearchResultsCollectionViewController"
        )
        
        
        internal static let chatsContainerViewController = SceneType<ChatsContainerViewController>(
            storyboard: Dashboard.self,
            identifier: "ChatsContainerViewController"
        )
        
        internal static let feedItemDetailVC = SceneType<FeedItemDetailVC>(
            storyboard: Dashboard.self,
            identifier: "FeedItemDetailVC"
        )
        
        
        internal static let chatsCollectionViewController = SceneType<ChatsCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "ChatsCollectionViewController"
        )
        
        internal static let feedFilterChipsCollectionViewController = SceneType<FeedFilterChipsCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "FeedFilterChipsCollectionViewController"
        )
        
        
        internal static let podcastFeedCollectionViewController = SceneType<PodcastFeedCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "PodcastFeedCollectionViewController"
        )
        
        
        internal static let videoFeedCollectionViewController = SceneType<DashboardVideoFeedCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "VideoFeedCollectionViewController"
        )
        
        internal static let newsletterFeedCollectionViewController = SceneType<DashboardNewsletterFeedCollectionViewController>(
            storyboard: Dashboard.self,
            identifier: "NewsletterFeedCollectionViewController"
        )
        
    }
    
    internal enum LeftMenu: StoryboardType {
        internal static let storyboardName = "LeftMenu"
        
        internal static let leftMenuViewController = SceneType<LeftMenuViewController>(storyboard: LeftMenu.self, identifier: "LeftMenuViewController")
        
        internal static let supportViewController = SceneType<SupportViewController>(storyboard: LeftMenu.self, identifier: "SupportViewController")
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
        
        internal static let profileManageStorageViewController = SceneType<ProfileManageStorageViewController>(storyboard: Profile.self, identifier: "ProfileManageStorageViewController")
        
        internal static let profileManageStorageSourceDetailsVC = SceneType<ProfileManageStorageSourceDetailsVC>(storyboard: Profile.self, identifier: "ProfileManageStorageSourceDetailsVC")
        
        internal static let profileManageStorageSpecificChatOrContentFeedItemVC = SceneType<ProfileManageStorageSpecificChatOrContentFeedItemVC>(storyboard: Profile.self, identifier: "ProfileManageStorageSpecificChatOrContentFeedItemVC")
        
        internal static let notificationSoundViewController = SceneType<NotificationSoundViewController>(storyboard: Profile.self, identifier: "NotificationSoundViewController")
    }
    
    internal enum Invite: StoryboardType {
        internal static let storyboardName = "Invite"
        
        internal static let inviteWelcomeViewController = SceneType<InviteWelcomeViewController>(storyboard: Invite.self, identifier: "InviteWelcomeViewController")
        
        internal static let setProfileImageViewController = SceneType<SetProfileImageViewController>(storyboard: Invite.self, identifier: "SetProfileImageViewController")
        
        internal static let setNickNameViewController = SceneType<SetNickNameViewController>(storyboard: Invite.self, identifier: "SetNickNameViewController")
        
        internal static let sphinxReadyViewController = SceneType<SphinxReadyViewController>(storyboard: Invite.self, identifier: "SphinxReadyViewController")
        
        internal static let addFriendViewController = SceneType<AddFriendViewController>(storyboard: Invite.self, identifier: "AddFriendViewController")
        
        internal static let confirmAddFriendViewController = SceneType<ConfirmAddFriendViewController>(storyboard: Invite.self, identifier: "ConfirmAddFriendViewController")
        
        internal static let shareInviteCodeViewController = SceneType<ShareInviteCodeViewController>(storyboard: Invite.self, identifier: "ShareInviteCodeViewController")
        
        internal static let keychainRestoreViewController = SceneType<KeychainRestoreViewController>(storyboard: Invite.self, identifier: "KeychainRestoreViewController")
    }
    
    internal enum BadgeManagement : StoryboardType{
        internal static let storyboardName = "BadgeManagement"
        
        internal static let badgeManagementListViewController = SceneType<UIViewController>(storyboard: BadgeManagement.self, identifier: "BadgeManagementListVC")
        internal static let badgeDetailViewController = SceneType<UIViewController>(storyboard: BadgeManagement.self, identifier: "BadgeDetailViewController")
        
        internal static let memberBadgeDetailVC = SceneType<UIViewController>(storyboard: BadgeManagement.self, identifier: "MemberBadgeDetailVC")
        
        internal static let badgeMemberKnownBadgesVC = SceneType<UIViewController>(storyboard: BadgeManagement.self, identifier: "BadgeMemberKnownBadgesVC")
    }
    
    internal enum Welcome: StoryboardType {
        internal static let storyboardName = "Welcome"
        
        internal static let initialWelcomeViewController = SceneType<InitialWelcomeViewController>(storyboard: Welcome.self, identifier: "InitialWelcomeViewController")
        
        internal static let welcomeCompleteViewController = SceneType<WelcomeCompleteViewController>(storyboard: Welcome.self, identifier: "WelcomeCompleteViewController")
        
        internal static let discoverTribesWebViewController = SceneType<DiscoverTribesWebViewController>(storyboard: Welcome.self, identifier: "DiscoverTribesWebViewController")
        
        internal static let discoverTribesTagSelectionViewController = SceneType<DiscoverTribesTagSelectionVC>(storyboard: Welcome.self, identifier: "DiscoverTribesTagSelectionVC")
    }
    
    internal enum RestoreUser: StoryboardType {
        internal static let storyboardName = "RestoreUser"
        
        internal static let restoreUserDescriptionViewController = SceneType<RestoreUserDescriptionViewController>(storyboard: RestoreUser.self, identifier: "RestoreUserDescriptionViewController")
        
        internal static let restoreUserFormViewController = SceneType<RestoreUserFormViewController>(storyboard: RestoreUser.self, identifier: "RestoreUserFormViewController")
        
        internal static let restoreUserConnectingViewController = SceneType<RestoreUserConnectingViewController>(storyboard: RestoreUser.self, identifier: "RestoreUserConnectingViewController")
    }
    
    
    internal enum NewUserSignup: StoryboardType {
        internal static let storyboardName = "NewUserSignup"
        
        
        internal static let newUserSignupOptionsViewController = SceneType<NewUserSignupOptionsViewController>(storyboard: NewUserSignup.self, identifier: "NewUserSignupOptionsViewController")
        
        internal static let newUserSignupDescriptionViewController = SceneType<NewUserSignupDescriptionViewController>(storyboard: NewUserSignup.self, identifier: "NewUserSignupDescriptionViewController")
        
        internal static let newUserSignupFormViewController = SceneType<NewUserSignupFormViewController>(storyboard: NewUserSignup.self, identifier: "NewUserSignupFormViewController")
        
        internal static let newUserGreetingViewController = SceneType<NewUserGreetingViewController>(storyboard: NewUserSignup.self, identifier: "NewUserGreetingViewController")
        
        internal static let sphinxDesktopAdViewController = SceneType<SphinxDesktopAdViewController>(storyboard: NewUserSignup.self, identifier: "SphinxDesktopAdViewController")
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
        
        internal static let joinGroupDetailsViewController = SceneType<JoinGroupDetailsViewController>(storyboard: Groups.self, identifier: "JoinGroupDetailsViewController")
        
        internal static let newPublicGroupViewController = SceneType<NewPublicGroupViewController>(storyboard: Groups.self, identifier: "NewPublicGroupViewController")
        
        internal static let groupTagsViewController = SceneType<GroupTagsViewController>(storyboard: Groups.self, identifier: "GroupTagsViewController")
        
        internal static let addTribeMemberViewController = SceneType<AddTribeMemberViewController>(storyboard: Groups.self, identifier: "AddTribeMemberViewController")
    }
    
    internal enum Stakwork: StoryboardType {
        
        internal static let storyboardName = "Stakwork"
        
        internal static let stakworkAuthorizeViewController = SceneType<StakworkAuthorizeViewController>(storyboard: Stakwork.self, identifier: "StakworkAuthorizeViewController")
    }
    
    internal enum People: StoryboardType {
        
        internal static let storyboardName = "People"
        
        internal static let peopleModalsViewController = SceneType<PeopleModalsViewController>(storyboard: People.self, identifier: "PeopleModalsViewController")
    }
    
    internal enum WebApps: StoryboardType {
        internal static let storyboardName = "WebApps"
        
        internal static let webAppViewController = SceneType<WebAppViewController>(storyboard: WebApps.self, identifier: "WebAppViewController")
        
        internal static let newPodcastPlayerViewController = SceneType<NewPodcastPlayerViewController>(storyboard: WebApps.self, identifier: "NewPodcastPlayerViewController")
        
        internal static let itemDescriptionViewController = SceneType<ItemDescriptionViewController>(storyboard: WebApps.self, identifier: "ItemDescriptionViewController")
        
        internal static let podcastAnimationViewController = SceneType<PodcastAnimationViewController>(storyboard: WebApps.self, identifier: "PodcastAnimationViewController")
        
        internal static let pickerViewController = SceneType<PickerViewController>(storyboard: WebApps.self, identifier: "PickerViewController")
        
        internal static let podcastNewEpisodeViewController = SceneType<PodcastNewEpisodeViewController>(storyboard: WebApps.self, identifier: "PodcastNewEpisodeViewController")
    }
    
    
    internal enum VideoFeed: StoryboardType {
        internal static let storyboardName = "VideoFeed"
        
        
        internal static let videoFeedEpisodePlayerContainerViewController = SceneType<VideoFeedEpisodePlayerContainerViewController>(storyboard: VideoFeed.self, identifier: "VideoFeedEpisodePlayerContainerViewController")
        
        
        internal static let youtubeVideoFeedEpisodePlayerViewController = SceneType<YouTubeVideoFeedEpisodePlayerViewController>(storyboard: VideoFeed.self, identifier: "YouTubeVideoFeedEpisodePlayerViewController")

        
        internal static let generalVideoFeedEpisodePlayerViewController = SceneType<GeneralVideoFeedEpisodePlayerViewController>(storyboard: VideoFeed.self, identifier: "GeneralVideoFeedEpisodePlayerViewController")
        
        
        internal static let videoFeedEpisodePlayerCollectionViewController = SceneType<VideoFeedEpisodePlayerCollectionViewController>(storyboard: VideoFeed.self, identifier: "VideoFeedEpisodePlayerCollectionViewController")
    }
    
    internal enum NewsletterFeed: StoryboardType {
        internal static let storyboardName = "NewsletterFeed"
        
        
        internal static let newsletterItemDetailViewController = SceneType<NewsletterItemDetailViewController>(storyboard: NewsletterFeed.self, identifier: "NewsletterItemDetailViewController")
        
        internal static let newsletterFeedContainerViewController = SceneType<NewsletterFeedContainerViewController>(storyboard: NewsletterFeed.self, identifier: "NewsletterFeedContainerViewController")
        
        internal static let newsletterFeedItemsCollectionViewController = SceneType<NewsletterFeedItemsCollectionViewController>(storyboard: NewsletterFeed.self, identifier: "NewsletterFeedItemsCollectionViewController")
    }
    
    internal enum Recommendations: StoryboardType {
        internal static let storyboardName = "Recommendations"
        
        internal static let recommendationFeedPlayerContainerViewController = SceneType<RecommendationFeedPlayerContainerViewController>(storyboard: Recommendations.self, identifier: "RecommendationFeedPlayerContainerViewController")
        
        internal static let youtubeRecommendationFeedPlayerViewController = SceneType<YoutubeRecommendationFeedPlayerViewController>(storyboard: Recommendations.self, identifier: "YoutubeRecommendationFeedPlayerViewController")
        
        internal static let podcastRecommendationFeedPlayerViewController = SceneType<PodcastRecommendationFeedPlayerViewController>(storyboard: Recommendations.self, identifier: "PodcastRecommendationFeedPlayerViewController")
        
        internal static let recommendationFeedItemsCollectionViewController = SceneType<RecommendationFeedItemsCollectionViewController>(storyboard: Recommendations.self, identifier: "RecommendationFeedItemsCollectionViewController")
        
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
