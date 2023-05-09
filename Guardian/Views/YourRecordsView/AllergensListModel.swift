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
        guard let allergen = record["allergen"] as? String,
              let totalNumberOfEpisodes = record["totalNumberOfEpisodes"] as? Int,
              let totalNumberOfMedicalTests = record["totalNumberOfMedicalTests"] as? Int else {
            return nil
        }
        
        headline = allergen
        caption1 = String(totalNumberOfMedicalTests)
        caption2 = String(totalNumberOfEpisodes)
        self.record = record
        //        caption1 = String(format: "%d", diagnosisDate.dateFormat)
    }
    
    init?(entity: AllergenEntity) {
        let myRecord = CKRecord(recordType: "Allergens", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        myRecord["allergen"] = entity.allergen
        myRecord["totalNumberOfEpisodes"] = entity.totalNumberOfEpisodes
        myRecord["totalNumberOfMedicalTests"] = entity.totalNumberOfMedicalTests
        let recordID = CKRecord.ID.init(recordName: entity.profileID!)
        let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
        myRecord["profile"] = reference as CKRecordValue
        self.init(record: myRecord)
    }
}
