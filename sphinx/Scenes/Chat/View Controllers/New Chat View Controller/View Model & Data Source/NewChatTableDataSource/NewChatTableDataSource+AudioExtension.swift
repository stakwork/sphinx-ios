//
//  NewChatTableDataSource+AudioExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation

extension NewChatTableDataSource : AudioPlayerHelperDelegate {
    func progressCallback(
        messageId: Int?,
        rowIndex: Int?,
        duration: Double,
        currentTime: Double
    ) {
        updateAudioInfoFor(
            messageId: messageId,
            rowIndex: rowIndex,
            playing: true,
            duration: duration,
            currentTime: currentTime
        )
    }
    
    func pauseCallback(
        messageId: Int?,
        rowIndex: Int?
    ) {
        updateAudioInfoFor(
            messageId: messageId,
            rowIndex: rowIndex,
            playing: false,
            duration: nil,
            currentTime: nil
        )
    }
    
    func endCallback(
        messageId: Int?,
        rowIndex: Int?
    ) {
        updateAudioInfoFor(
            messageId: messageId,
            rowIndex: rowIndex,
            playing: false,
            duration: nil,
            currentTime: 0
        )
    }
    
    func updateAudioInfoFor(
        messageId: Int?,
        rowIndex: Int?,
        playing: Bool,
        duration: Double?,
        currentTime: Double?
    ) {
        guard let messageId = messageId, let rowIndex = rowIndex else {
            return
        }
        
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            if let audioData = mediaCached[messageId], let audioInfo = audioData.audioInfo {
                
                mediaCached[messageId] = MessageTableCellState.MediaData(
                    data: audioData.data,
                    audioInfo: MessageTableCellState.AudioInfo(
                        playing: playing,
                        duration: duration ?? audioInfo.duration,
                        currentTime: currentTime ?? audioInfo.currentTime
                    )
                )
                
                DispatchQueue.main.async {
                    var snapshot = self.dataSource.snapshot()
                    snapshot.reloadItems([tableCellState.1])
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
            }
        }
    }
}
