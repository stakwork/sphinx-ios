//
//  Download.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation

class Download {
    var isDownloading = false
    var progress: Int = 0
    var resumeData: Data?
    var task: URLSessionDownloadTask?
    var episode: PodcastEpisode

    init(episode: PodcastEpisode) {
        self.episode = episode
    }
}
