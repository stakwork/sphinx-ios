//
//  NotificationSoundHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

class NotificationSoundHelper {
    
    public struct Sound {
        var name : String
        var file : String
        var selected : Bool = false
        
        init(name: String, file: String, selected: Bool) {
            self.name = name
            self.file = file
            self.selected = selected
        }
    }
    
    var sounds = [Sound]()
    
    init() {
        sounds.append(Sound(name: "TriTone (default)", file: "tri-tone.caf", selected: true))
        sounds.append(Sound(name: "Aurora", file: "aurora.caf", selected: false))
        sounds.append(Sound(name: "Bamboo", file: "bamboo.caf", selected: false))
        sounds.append(Sound(name: "Bell", file: "bell.caf", selected: false))
        sounds.append(Sound(name: "Bells", file: "bells.caf", selected: false))
        sounds.append(Sound(name: "Glass", file: "glass.caf", selected: false))
        sounds.append(Sound(name: "Horn", file: "horn.caf", selected: false))
        sounds.append(Sound(name: "Note", file: "note.caf", selected: false))
        sounds.append(Sound(name: "Popcorn", file: "popcorn.caf", selected: false))
        sounds.append(Sound(name: "Synth", file: "synth.caf", selected: false))
        sounds.append(Sound(name: "Tweet", file: "tweet.caf", selected: false))
    }
    
    func selectUserSound(file: String?) -> String {
        let fileName = file ?? "tri-tone.caf"
        
        for i in 0..<sounds.count {
            var sound = sounds[i]
            sound.selected = sound.file == fileName
            sounds[i] = sound
        }
        
        return getNameFor(file: file)
    }
    
    func getNameFor(file: String?) -> String {
        let fileName = file ?? "tri-tone.caf"
        
        for sound in sounds {
            if sound.file == fileName {
                return sound.name
            }
        }
        
        return sounds[0].name
    }
    
    func getSounds() -> [Sound] {
        return sounds
    }
    
    func getSelectedSound() -> Sound {
        for sound in sounds {
            if sound.selected {
                return sound
            }
        }
        return sounds[0]
    }
    
    func updateSound(index: Int) {
        for i in 0..<sounds.count {
            var sound = sounds[i]
            sound.selected = i == index
            sounds[i] = sound
        }
    }
}
