//
//  DateFormatter.swift
//  Guardian
//
//  Created by Teff on 2023/03/18.
//

import Foundation

extension Date {
    var dateFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
