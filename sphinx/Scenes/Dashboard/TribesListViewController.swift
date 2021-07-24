//
//  TribesListViewController.swift
//  TribesListViewController
//
//  Created by Brian Sipple on 7/22/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class TribesListViewController: UIViewController {

    static func instantiate() -> TribesListViewController {
        let viewController = StoryboardScene.Dashboard.tribesListViewController.instantiate()
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
