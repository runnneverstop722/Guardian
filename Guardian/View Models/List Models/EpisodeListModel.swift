//
//  EpisodeListModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/30.
//

import SwiftUI
import PhotosUI
import CloudKit

struct EpisodeListModel: Identifiable, Hashable {
    
    let id = UUID()
    let headline: String
    let caption1: String
    let caption2: String
    let caption3: String
    let record: CKRecord
    
    init?(record: CKRecord) {
        guard let episodeDate = record["episodeDate"] as? Date,
              let firstKnownExposure = record["firstKnownExposure"] as? Bool,
              let wentToHospital = record["wentToHospital"] as? Bool,
              let typeOfExposure = record["typeOfExposure"] as? [String] else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        headline = dateFormatter.string(from: episodeDate)
        caption1 = firstKnownExposure  ? "初症状" : ""
        caption2 = wentToHospital ? "外来済" : ""
        caption3 = typeOfExposure.joined(separator: ", ")
        self.record = record
        //        caption1 = String(format: "%d", diagnosisDate.dateFormat)
    }
}
