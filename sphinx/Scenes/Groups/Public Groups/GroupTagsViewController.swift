//
//  GroupTagsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupTagsViewController: UIViewController {
    
    @IBOutlet weak var tagsTableView: UITableView!
    
    let groupsManager = GroupsManager.sharedInstance
    
    static func instantiate() -> GroupTagsViewController {
        let viewController = StoryboardScene.Groups.groupTagsViewController.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    func configureTableView() {
        tagsTableView.registerCell(GroupTagTableViewCell.self)
        tagsTableView.delegate = self
        tagsTableView.dataSource = self
        tagsTableView.reloadData()
    }
}

extension GroupTagsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? GroupTagTableViewCell {
            let tag = groupsManager.newGroupInfo.tags[indexPath.row]
            cell.configureWith(tag: tag)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SoundsPlayer.playHaptic()
        updateTag(index: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func updateTag(index: Int) {
        var tag = groupsManager.newGroupInfo.tags[index]
        tag.selected = !tag.selected
        groupsManager.newGroupInfo.tags[index] = tag
    }
}

extension GroupTagsViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsManager.newGroupInfo.tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupTagTableViewCell", for: indexPath) as! GroupTagTableViewCell
        return cell
    }
}
