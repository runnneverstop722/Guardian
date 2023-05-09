//
//  AllergensModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/29.
//

import CloudKit

struct AllergensModel: Identifiable, Hashable {
    
    let id = UUID()
    let allergen: String
    let record: CKRecord
    
    init?(record: CKRecord) {
        guard let name = record["allergen"] as? String else { return nil }
        allergen = name
        self.record = record
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
