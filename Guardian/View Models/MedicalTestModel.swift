//
//  MedicalTestModel.swift
//  Guardian
//
//  Created by Teff on 2023/04/02.
//

import SwiftUI
import CloudKit

@MainActor class MedicalTestModel: ObservableObject {
 
    enum BloodTestGrade: String, CaseIterable {
        case negative = "陰性(~0.35)"
        case grade1 = "グレード1"
        case grade2 = "グレード2"
        case grade3 = "グレード3"
        case grade4 = "グレード4"
        case grade5 = "グレード5"
        case grade6 = "グレード6"
    }
    
    @Published var bloodTestDate: Date = Date()
    @Published var bloodTestLevel: String = ""
    @Published var bloodTestGrade: BloodTestGrade = .negative
    
    @Published var skinTestDate: Date = Date()
    @Published var SkinTestResultValue: String = ""
    @Published var SkinTestResult: Bool = false
    
    @Published var oralFoodChallengeDate: Date = Date()
    @Published var oralFoodChallengeQuantity: String = ""
    @Published var oralFoodChallengeResult: Bool = false
    
    @Published var bloodTestInfo: [BloodTest] = []
    @Published var skinTestInfo: [SkinTest] = []
    @Published var OFCInfo: [OralFoodChallenge] = []
    
    var totalNumberOfBloodTest: Int {
        return bloodTestInfo.count
    }
    var totalNumberOfSkinTest: Int {
        return skinTestInfo.count
    }
    var totalNumberOfOFC: Int {
        return OFCInfo.count
    }
    
    var record: CKRecord
    
    init(record: CKRecord) {
        self.record = record
        fetchData()
    }
    
    
    
    //MARK: - Fetch
    
    private func fetchData() {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)
        
        //MARK: - Blood
        
        let bloodTestQuery = CKQuery(recordType: "BloodTest", predicate: predicate)
        bloodTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let bloodTestQueryOperation = CKQueryOperation(query: bloodTestQuery)
        bloodTestQueryOperation.queuePriority = .veryHigh
        
        self.bloodTestInfo = []
        bloodTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = BloodTest(record: returnedRecord) {
                    self.bloodTestInfo.append(object)
                }
            }
        }
        bloodTestQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED 'Blood Test' queryResultBlock")
        }
        addOperation(operation: bloodTestQueryOperation)
        
        //MARK: - Skin
        
        let skinTestQuery = CKQuery(recordType: "SkinTest", predicate: predicate)
        skinTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let skinTestQueryOperation = CKQueryOperation(query: skinTestQuery)
        skinTestQueryOperation.queuePriority = .veryHigh
        
        self.skinTestInfo = []
        skinTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = SkinTest(record: returnedRecord) {
                    self.skinTestInfo.append(object)
                }
            }
        }
        skinTestQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED 'Skin Test' queryResultBlock")
        }
        addOperation(operation: skinTestQueryOperation)
        
        //MARK: - OFC
        
        let OFCQuery = CKQuery(recordType: "OralFoodChallenge", predicate: predicate)
        OFCQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let OFCQueryOperation = CKQueryOperation(query: OFCQuery)
        OFCQueryOperation.queuePriority = .veryHigh
        
        self.skinTestInfo = []
        OFCQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = OralFoodChallenge(record: returnedRecord) {
                    self.OFCInfo.append(object)
                }
            }
        }
        OFCQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED 'Oral Food Challenge' queryResultBlock")
        }
        
        addOperation(operation: OFCQueryOperation)
    }
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    
    //MARK: - Func Save
    func saveData() {
        updateData()
        
        let newBloodTests = bloodTestInfo.filter { $0.record == nil }
        let newSkinTests = skinTestInfo.filter { $0.record == nil }
        let newOFC = OFCInfo.filter { $0.record == nil }
        
        newBloodTests.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "BloodTest", recordID: ckRecordID)
            
            myRecord["bloodTestDate"] = $0.bloodTestDate
            myRecord["bloodTestLevel"] = $0.bloodTestLevel
            myRecord["bloodTestGrade"] = $0.bloodTestGrade.rawValue
            
            let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
        
        newSkinTests.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "SkinTest", recordID: ckRecordID)
            
            myRecord["skinTestDate"] = $0.skinTestDate
            myRecord["SkinTestResultValue"] = $0.SkinTestResultValue
            myRecord["SkinTestResult"] = $0.SkinTestResult
            
            let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
        
        newOFC.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "OralFoodChallenge", recordID: ckRecordID)
            
            myRecord["oralFoodChallengeDate"] = $0.oralFoodChallengeDate
            myRecord["oralFoodChallengeQuantity"] = $0.oralFoodChallengeQuantity
            myRecord["oralFoodChallengeResult"] = $0.oralFoodChallengeResult
            
            let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
    }
    
    //MARK: - Func Update
    func updateData() {
        
    }
    
    private func save(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
        }
    }


    
    
    
    
    
    
    
    
    
}
