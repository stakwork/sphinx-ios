//
//  Download.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Foundation

class Download {
    var state: State = State.ready
    var progress: Int = 0
    var resumeData: Data?
    var originalUrl: String?
    var task: URLSessionDownloadTask?
    var episode: PodcastEpisode

    init(episode: PodcastEpisode) {
        self.episode = episode
        self.originalUrl = episode.getRemoteAudioUrl()?.absoluteString
    }
    
    enum State: String {
        case ready
        case downloading
        case paused
    }
    
    var isDownloading: Bool {
        get {
            return state == State.downloading
        }
    }
    
    var isPaused: Bool {
        get {
            return state == State.paused || resumeData != nil
        }
    }
    
    var isReady: Bool {
        get {
            return state == State.ready || resumeData == nil
        }
    }
}


class VideoDownload {
    var state: State = State.ready
    var progress: Int = 0
    var resumeData: Data?
    var originalUrl: String?
    var task: URLSessionDownloadTask?
    var video: Video

    init(video: Video) {
        self.video = video
        self.originalUrl = video.itemURL?.absoluteString
    }
    
    enum State: String {
        case ready
        case downloading
        case paused
    }
    
    var isDownloading: Bool {
        get {
            return state == State.downloading
        }
    }
    
    var isPaused: Bool {
        get {
            return state == State.paused || resumeData != nil
        }
    }
    
    var isReady: Bool {
        get {
            return state == State.ready || resumeData == nil
        }
    }
}
