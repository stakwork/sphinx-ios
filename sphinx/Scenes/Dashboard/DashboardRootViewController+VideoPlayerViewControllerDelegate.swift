// DashboardRootViewController+VideoPlayerViewControllerDelegate.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


extension DashboardRootViewController: VideoFeedEpisodePlayerViewControllerDelegate {
    
    func viewControllerShouldDismiss(
        _ viewController: UIViewController
    ) {
        navigationController?.popViewController(animated: true)
    }
}
