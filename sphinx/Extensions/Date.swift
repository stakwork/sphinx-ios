//
//  Date.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation

extension Date {
    var dayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self) ?? 0
    }
    
    var monthOfYear: Int {
        return Calendar.current.ordinality(of: .month, in: .year, for: self) ?? 0
    }
    
    func getStringDate(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
    
    func getStringFromDate(format:String, timeZone: TimeZone = TimeZone(abbreviation: "UTC")!) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = timeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self)
    }
    
    func getMinutesDifference(from date: Date) -> Int {
        let timeInterval = self.timeIntervalSince(date)
        let minutes = timeInterval / Double(60)
        return abs(Int(minutes))
    }
    
    func getHousDifference(from date: Date) -> Int {
        let timeInterval = self.timeIntervalSince(date)
        let hours = timeInterval / Double(3600)
        return abs(Int(ceil(hours)))
    }
    
    public static func getDateFromString(dateString: String?) -> Date? {
        if let dateString = dateString {
            
            let dateFormats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
            ]
            
            for format in dateFormats {
                let dateSubstring = dateString.substring(toIndex: format.count)
                if let date = getDateFromString(dateString: dateSubstring, format: format) {
                    return date
                }
            }
        }
        return nil
    }
    
    public static func getDateFromString(dateString: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+00")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: dateString)
    }
    
    public static func isDifferentDay(firstDate: Date, secondDate: Date) -> Bool {
        let cal = Calendar.current
        if let firstDay = cal.ordinality(of: .day, in: .year, for: firstDate),
           let secondDay = cal.ordinality(of: .day, in: .year, for: secondDate) {
            
            let firstYear = cal.component(.year, from: firstDate)
            let secondYear = cal.component(.year, from: secondDate)
            
            return secondDay != firstDay || secondYear != firstYear
        }
        return true
   }
    
    func shouldShowMonthAndYear() -> (Bool, Bool) {
        let cal = Calendar.current
        let dateMonth = self.monthOfYear
        let dateYear = cal.component(.year, from: self)

        let currentMonth = Date().monthOfYear
        let currentYear = cal.component(.year, from: Date())

        return ((dateMonth != currentMonth || dateYear != currentYear), dateYear != currentYear)
    }
    
    func isToday() -> Bool {
        let cal = Calendar.current
        let dateDayOfYear = self.dayOfYear
        let dateYear = cal.component(.year, from: self)
        let todayDayOfYear = Date().dayOfYear
        let todayYear = cal.component(.year, from: Date())

        return (dateDayOfYear == todayDayOfYear && dateYear == todayYear)
    }
    
    public func daySuffix() -> String {
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: self)
        switch dayOfMonth {
            case 1, 21, 31: return "st"
            case 2, 22: return "nd"
            case 3, 23: return "rd"
            default: return "th"
        }
    }
    
    public func getLastMessageDateFormat() -> String {
        let todayDay = Date().dayOfYear
        let dateDay = self.dayOfYear
        
        let todayMonth = Date().monthOfYear
        let dateMonth = self.monthOfYear
        
        if todayDay == dateDay {
            return self.getStringDate(format: "h:mm a")
        } else {
            if todayMonth == dateMonth {
                return self.getStringDate(format: "EEE dd")
            } else {
                return self.getStringDate(format: "EEE dd MMM")
            }
        }
    }
    
    func changeDays(by days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    var publishDateString: String {
        let calendar = Calendar.autoupdatingCurrent
        
        let dateComponents = calendar.dateComponents(
            [
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
            ],
            from: Date(),
            to: self
        )

        return RelativeDateTimeFormatter().localizedString(
            from: dateComponents
        )
    }
}
