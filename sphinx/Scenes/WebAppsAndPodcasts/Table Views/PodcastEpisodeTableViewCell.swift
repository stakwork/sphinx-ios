//
//  PodcastEpisodeTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PodcastEpisodeRowDelegate : class {
    func shouldStartDownloading(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldDeleteFile(episode: PodcastEpisode, cell: UITableViewCell)
    func shouldShare(episode: PodcastEpisode)
    func shouldShowMore(episode: PodcastEpisode,cell:UITableViewCell)
}

class PodcastEpisodeTableViewCell: SwipableCell {
    
    weak var delegate: PodcastEpisodeRowDelegate?
    
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var playArrow: UILabel!
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var progressLabel: UILabel!
    
    var episode: PodcastEpisode! = nil
    
    public static var podcastImage: UIImage? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberOfButtons = .oneButton
        button3 = button1
        button1.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(podcast: PodcastFeed?,
                       and episode: PodcastEpisode,
                       download: Download?,
                       delegate: PodcastEpisodeRowDelegate,
                       isLastRow: Bool,
                       playing: Bool) {
        
        self.episode = episode
        self.delegate = delegate
        
        contentView.backgroundColor = playing ? UIColor.Sphinx.ChatListSelected : UIColor.clear
        playArrow.isHidden = !playing
        
        episodeLabel.text = episode.title ?? "No title"
        divider.isHidden = isLastRow
        
        configureDownload(episode: episode, download: download)
        
        episodeImageView.sd_cancelCurrentImageLoad()
        
        if let episodeURLPath = episode.imageURLPath, let url = URL(string: episodeURLPath) {
            episodeImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else if let podcastURLPath = podcast?.imageURLPath, let url = URL(string: podcastURLPath) {
            episodeImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        }
    }
    
    func configureDownload(episode: PodcastEpisode, download: Download?) {
        contentView.alpha = episode.isAvailable ? 1.0 : 0.5

        recognizer?.isEnabled = episode.isDownloaded
        
        progressLabel.text = ""

        if episode.isDownloaded {
            downloadButton.setTitle("download_done", for: .normal)
            downloadButton.setTitleColor(UIColor.Sphinx.PrimaryGreen, for: .normal)
        } else {
            downloadButton.setTitle("download", for: .normal)
            downloadButton.setTitleColor(UIColor.Sphinx.Text, for: .normal)
        }
        
        if let download = download {
            updateProgress(progress: download.progress)
        }
    }
    
    func updateProgress(progress: Int) {
        progressLabel.text = (progress > 0) ? "\(progress)%" : ""
        downloadButton.setTitle((progress > 0) ? "" : "hourglass_top", for: .normal)
    }
    
    func isDifferentEpisode(episodeId: Int) -> Bool {
        return episodeId != Int(episode.itemID)
    }
    
    @IBAction func downloadButtonTouched() {
        self.delegate?.shouldStartDownloading(episode: episode, cell: self)
    }
    
    
    @IBAction func deleteButtonTouched() {
        delegate?.shouldDeleteFile(episode: episode, cell: self)
    }
}
