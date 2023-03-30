//
//  AllergensListModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/30.
//

import SwiftUI
import PhotosUI
import CloudKit

struct AllergensListModel: Identifiable, Hashable {
    
    let id = UUID()
    let headline: String
    let caption1: String
    let caption2: String
    let record: CKRecord
    
    init?(record: CKRecord) {
        guard let allergens = record["allergens"] as? String,
              let totalNumberOfEpisodes = record["totalNumberOfEpisodes"] as? String,
              let totalNumberOfMedicalTests = record["totalNumberOfMedicalTests"] as? String else {
            return nil
        }
        
        headline = allergens
        caption1 = totalNumberOfEpisodes
        caption2 = totalNumberOfMedicalTests
        self.record = record
        //        caption1 = String(format: "%d", diagnosisDate.dateFormat)
    }
}
