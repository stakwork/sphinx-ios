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
    var progress: Int = 0 {
        didSet{
            progressBuffer[progressIndex] = progress
            if(progressIndex < progressBuffer.count - 1){
                progressIndex += 1
            }
            else{
                progressIndex = 0
            }
        }
    }
    var progressIndex : Int = 0
    var progressBuffer : [Int] = [0,0,0,0,0,0,0,0]
    var resumeData: Data?
    var task: URLSessionDownloadTask?
    var episode: PodcastEpisode
    
    func getAverageProgress()->Int{
        var average : Int = 0
        for datapoint in progressBuffer{
            average += (datapoint)/progressBuffer.count
        }
        return average
    }

    init(episode: PodcastEpisode) {
        self.episode = episode
    }
}
