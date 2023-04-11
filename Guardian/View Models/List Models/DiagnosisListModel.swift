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
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let formattedDate = dateFormatter.string(from: diagnosisDate)
        caption1 = formattedDate
        caption2 = allergens
        caption3 = hospitalName
        caption4 = allergist
        caption5 = allergistComment
        self.record = record
    }
    
    init?(entity: DiagnosisEntity) {
        let myRecord = CKRecord(recordType: "DiagnosisInfo", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        if let diagnosisPhoto = entity.diagnosisPhoto {
            let urls = diagnosisPhoto.map {
                let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = doc.appendingPathComponent($0)
                let asset = CKAsset(fileURL: filePath)
                return asset
            }
            myRecord["data"] = urls
        }
        myRecord["diagnosis"] = entity.diagnosis
        myRecord["diagnosisDate"] = entity.diagnosisDate
        myRecord["diagnosedHospital"] = entity.diagnosedHospital
        myRecord["diagnosedAllergist"] = entity.diagnosedAllergist
        myRecord["diagnosedAllergistComment"] = entity.diagnosedAllergistComment
        myRecord["allergens"] = entity.allergens
        let profileID = CKRecord.ID.init(recordName: entity.profileID!)
        let reference = CKRecord.Reference(recordID: profileID, action: .deleteSelf)
        myRecord["profile"] = reference as CKRecordValue
        self.init(record: myRecord)
    }
}
