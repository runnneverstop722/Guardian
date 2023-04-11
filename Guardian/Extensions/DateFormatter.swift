//
//  DateFormatter.swift
//  Guardian
//
//  Created by Teff on 2023/03/18.
//

import Foundation

//extension Date {
//    var dateFormat: String {
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "ja_JP")
//        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .none
//        return formatter.string(from: self)
//    }
//}
extension Date {
    
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale   = .current
        return calendar
    }
    
    var year: Int {
            return calendar.component(.year, from: self)
        }
        
        var month: Int {
            return calendar.component(.month, from: self)
        }
        
        var day: Int {
            return calendar.component(.day, from: self)
        }
        
        var hour: Int {
            return calendar.component(.hour, from: self)
        }
        
        var minute: Int {
            return calendar.component(.minute, from: self)
        }
        
        var second: Int {
            return calendar.component(.second, from: self)
        }
    
    var weekName: String {
            let index = calendar.component(.weekday, from: self) - 1 // index値を 1〜7 から 0〜6 にしている
            return ["日", "月", "火", "水", "木", "金", "土"][index]
        }
    
    init(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) {
            self.init(
                timeIntervalSince1970: Date().fixed(
                    year:   year,
                    month:  month,
                    day:    day,
                    hour:   hour,
                    minute: minute,
                    second: second
                ).timeIntervalSince1970
            )
        }
    
    func fixed(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date {
            let calendar = self.calendar
            
            var comp = DateComponents()
            comp.year   = year   ?? calendar.component(.year,   from: self)
            comp.month  = month  ?? calendar.component(.month,  from: self)
            comp.day    = day    ?? calendar.component(.day,    from: self)
            comp.hour   = hour   ?? calendar.component(.hour,   from: self)
            comp.minute = minute ?? calendar.component(.minute, from: self)
            comp.second = second ?? calendar.component(.second, from: self)
            
            return calendar.date(from: comp)!
        }
    
    
}
