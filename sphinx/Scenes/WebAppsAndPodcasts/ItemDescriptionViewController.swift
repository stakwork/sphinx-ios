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
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func setupTableView(){
        tableView.register(UINib(nibName: "ItemDescriptionTableViewHeaderCell", bundle: nil), forCellReuseIdentifier: ItemDescriptionTableViewHeaderCell.reuseID)
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ItemDescriptionViewController : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ItemDescriptionTableViewHeaderCell.reuseID,
                for: indexPath
            ) as! ItemDescriptionTableViewHeaderCell
        cell.configureView(podcast: podcast, episode: episode)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
}
