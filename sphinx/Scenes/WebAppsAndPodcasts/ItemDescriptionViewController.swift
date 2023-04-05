//
//  ItemDescriptionViewController.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ItemDescriptionViewController : UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navbarPodcastTitle: UILabel!
    @IBOutlet weak var navBarPlayButton: UILabel!
    
    var podcast : PodcastFeed!
    var episode: PodcastEpisode!
    
    var videoFeed:VideoFeed!
    var video:Video!
    
    var isExpanded : Bool = false
    
    override func viewDidLoad() {
        //self.view.backgroundColor = .purple
        setupTableView()
    }
    
    static func instantiate(
        podcast: PodcastFeed,
        episode: PodcastEpisode
    ) -> ItemDescriptionViewController {
        let viewController = StoryboardScene.WebApps.itemDescriptionViewController.instantiate()
        
        viewController.podcast = podcast
        viewController.episode = episode
    
        return viewController
    }
    
    static func instantiate(
        videoFeed:VideoFeed,
        video:Video
    )->ItemDescriptionViewController{
        let viewController = StoryboardScene.WebApps.itemDescriptionViewController.instantiate()
        
        viewController.video = video
        viewController.videoFeed = videoFeed
    
        return viewController
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupTableView(){
        navbarPodcastTitle.isHidden = true
        navbarPodcastTitle.isUserInteractionEnabled = false
        if let episode = episode{
            navbarPodcastTitle.text = episode.title
        }
        else if let video = video{
            navbarPodcastTitle.text = video.title
        }
        
        navBarPlayButton.isHidden = true
        navBarPlayButton.makeCircular()
        
        self.view.backgroundColor = UIColor.Sphinx.Body
        self.tableView.backgroundColor = UIColor.Sphinx.Body
        tableView.register(UINib(nibName: "ItemDescriptionTableViewHeaderCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewHeaderCell.reuseID)
        tableView.register(UINib(nibName: "ItemDescriptionTableViewCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewCell.reuseID)
        tableView.register(UINib(nibName: "ItemDescriptionImageTableViewCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionImageTableViewCell.reuseID)
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
}

extension ItemDescriptionViewController : UITableViewDelegate,UITableViewDataSource,ItemDescriptionTableViewCellDelegate,UIScrollViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionTableViewHeaderCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionTableViewHeaderCell
            if podcast != nil && episode != nil{
                cell.configureView(podcast: podcast, episode: episode)
            }
            else if video != nil && videoFeed != nil{
                cell.configureView(videoFeed: videoFeed, video: video)
            }
            else{
                return UITableViewCell()
            }
            cell.delegate = self
            
            return cell
        }
        else if indexPath.row == 1{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionTableViewCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionTableViewCell
            if episode != nil,
               let description = episode.episodeDescription{
                cell.configureView(descriptionText: description.nonHtmlRawString, isExpanded: self.isExpanded)
            }else{
                cell.configureView(descriptionText: "No description for this episode", isExpanded: false)
            }
            cell.delegate = self
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionImageTableViewCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionImageTableViewCell
            if episode != nil,
               let image = episode.imageToShow,
               let url = URL(string: image){
                cell.configureView(imageURL: url)
            }
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 && isExpanded{
            self.isExpanded = false
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.row == 0){
            return 270.0
        }
        else if(indexPath.row == 1){
            if(isExpanded),
              episode != nil,
              let description = episode.episodeDescription,
              let font = UIFont(name: "Roboto", size: 14.0){
                return calculateStringHeight(string: description, constraintedWidth: tableView.frame.width, font: font)
            }
            else{
                return 150.0
            }
        }
        else{
            return 342.0
        }
    }
    
    func didExpandCell() {
        self.isExpanded = true
        tableView.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            // write logic for tableview disble scrolling
            print("scrolling")
            if(tableView.isCellVisible(section: 0, row: 0)){
                if(navbarPodcastTitle.isHidden == false){
                    self.navbarPodcastTitle.alpha = 1.0
                    self.navBarPlayButton.alpha = 1.0
                    UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
                        self.navbarPodcastTitle.alpha = 0.0
                        self.navBarPlayButton.alpha = 0.0
                    },completion: {_ in
                        self.navbarPodcastTitle.isHidden = true
                        self.navBarPlayButton.isHidden = true
                    })
                }
            }
            else{
                if(navbarPodcastTitle.isHidden == true){
                    self.navbarPodcastTitle.alpha = 0.0
                    self.navBarPlayButton.alpha = 0.0
                    self.navbarPodcastTitle.isHidden = false
                    self.navBarPlayButton.isHidden = false
                    UIView.animate(withDuration: 0.25, delay: 0.0, animations: {
                        self.navbarPodcastTitle.alpha = 1.0
                        self.navBarPlayButton.alpha = 1.0
                    },
                    completion: {_ in
                        
                    })
                }
            }
        }
    }
    
    
    func calculateStringHeight(string:String,constraintedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = string
        label.font = font
        label.sizeToFit()

        return label.frame.height
     }
    
    @IBAction func navBarTapped(){
        self.tableView.scrollToRow(index: 0,animated: true)
    }
    
    @IBAction func tappedPlay(){
        print("play")
    }
}


extension UITableView {

    /// Check if cell at the specific section and row is visible
    /// - Parameters:
    /// - section: an Int reprenseting a UITableView section
    /// - row: and Int representing a UITableView row
    /// - Returns: True if cell at section and row is visible, False otherwise
    func isCellVisible(section:Int, row: Int) -> Bool {
        guard let indexes = self.indexPathsForVisibleRows else {
            return false
        }
        return indexes.contains {$0.section == section && $0.row == row }
    }
}

extension ItemDescriptionViewController : ItemDescriptionTableViewHeaderCellDelegate{
    func itemShareTapped(video: Video) {
        self.shareTapped(video: video)
    }
    
    func itemShareTapped(episode: PodcastEpisode) {
        self.askForShareType(episode: episode)
    }
}
