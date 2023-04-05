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
        tableView.register(UINib(nibName: "ItemDescriptionTableViewHeaderCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewHeaderCell.reuseID)
        tableView.register(UINib(nibName: "ItemDescriptionTableViewCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewCell.reuseID)
        tableView.register(UINib(nibName: "ItemDescriptionImageTableViewCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionImageTableViewCell.reuseID)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ItemDescriptionViewController : UITableViewDelegate,UITableViewDataSource,ItemDescriptionTableViewCellDelegate{
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
    
    
    func calculateStringHeight(string:String,constraintedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = string
        label.font = font
        label.sizeToFit()

        return label.frame.height
     }
}
