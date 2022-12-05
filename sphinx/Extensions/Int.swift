//
//  Int.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

extension Int {
    var timeString : String {
        if self < 10 {
            return "0\(self)"
        } else {
            return "\(self)"
        }
    }
    
    func getPodcastTimeString() -> String {
        let hours = Int((self % 86400) / 3600).timeString
        let minutes = Int((self % 3600) / 60).timeString
        let seconds = Int((self % 3600) % 60).timeString
        
        return "\(hours):\(minutes):\(seconds)"
    }
    
    var hoursFromMillis : Int {
        return self / 60 / 60 / 1000
    }
    
    var millisFromHours : Int {
        return self * 60 * 60 * 1000
    }
    
    var formattedSize : String {
        get {
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useAll]
            bcf.countStyle = .file
            return bcf.string(fromByteCount: Int64(self))
        }
    }
    
    var forcedNotZero: Int {
        if self <= 0 {
            return 1
        }
        return self
    }
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let withDotDecimalSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension Numeric {
    var formattedWithSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
    
    var formattedWithDotDecimalSeparator: String {
        return Formatter.withDotDecimalSeparator.string(for: self) ?? "\(self)"
    }
}
