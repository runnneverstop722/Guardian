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
    let caption4: String
    let caption5: String
    let record: CKRecord
    
    init?(record: CKRecord) {
        guard let episodeDate = record["episodeDate"] as? Date,
              let firstKnownExposure = record["firstKnownExposure"] as? Bool,
              let wentToHospital = record["wentToHospital"] as? Bool,
              let typeOfExposure = record["typeOfExposure"] as? [String],
              let symptoms = record["symptoms"] as? [String],
              let severity = record["severity"] as? String,
              let didExercise = record["didExercise"] as? Bool else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let formattedDate = dateFormatter.string(from: episodeDate)
        headline = formattedDate
        caption1 = firstKnownExposure  ? "初症状" : ""
        caption2 = wentToHospital ? "外来済" : ""
        caption3 = typeOfExposure.joined(separator: ", ")
        caption4 = symptoms.joined(separator: ", ")
        caption5 = didExercise ? "運動後" : ""
        self.record = record
    }
    
    init?(entity: EpisodeEntity) {
        let myRecord = CKRecord(recordType: "EpisodeInfo", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        if let diagnosisPhoto = entity.episodePhoto {
            let urls = diagnosisPhoto.map {
                let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = doc.appendingPathComponent($0)
                let asset = CKAsset(fileURL: filePath)
                return asset
            }
            myRecord["data"] = urls
        }
        myRecord["episodeDate"] = entity.episodeDate
        myRecord["firstKnownExposure"] = entity.firstKnownExposure
        myRecord["wentToHospital"] = entity.wentToHospital
        myRecord["typeOfExposure"] = entity.typeOfExposure
        myRecord["intakeAmount"] = entity.intakeAmount
        myRecord["symptoms"] = entity.symptoms
        myRecord["severity"] = entity.severity
        myRecord["leadTimeToSymptoms"] = entity.leadTimeToSymptoms
        myRecord["didExercise"] = entity.didExercise
        myRecord["treatments"] = entity.treatments
        myRecord["otherTreatment"] = entity.otherTreatment
        let allergenID = CKRecord.ID.init(recordName: entity.allergenID!)
        let reference = CKRecord.Reference(recordID: allergenID, action: .deleteSelf)
        myRecord["allergen"] = reference as CKRecordValue
        self.init(record: myRecord)
    }
}
