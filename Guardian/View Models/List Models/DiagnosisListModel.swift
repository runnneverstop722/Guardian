//
//  DiagnosisListModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/25.
//

import SwiftUI
import PhotosUI
import CloudKit

struct DiagnosisListModel: Identifiable, Hashable {
    
    let id = UUID()
    let headline: String
    let caption1: String
    let caption2: [String]
    let caption3: String
    let caption4: String
    let caption5: String
    let record: CKRecord
    
    init?(record: CKRecord) {
            guard let diagnosis = record["diagnosis"] as? String,
                  let diagnosisDate = record["diagnosisDate"] as? Date,
                  let allergens = record["allergens"] as? [String],
                  let hospitalName = record["diagnosedHospital"] as? String,
                  let allergist = record["diagnosedAllergist"] as? String,
                  let allergistComment = record["diagnosedAllergistComment"] as? String else {
                return nil
            }
        
        
        headline = String(format: "%@", diagnosis)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        caption1 = dateFormatter.string(from: diagnosisDate)
        caption2 = allergens
        caption3 = hospitalName
        caption4 = allergist
        caption5 = allergistComment
        self.record = record
        //        caption1 = String(format: "%d", diagnosisDate.dateFormat)
    }
}
