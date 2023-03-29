//  DiagnosisModel.swift

import SwiftUI
import CoreTransferable
import CloudKit

struct diagnosisInfoModel: Hashable, Identifiable {
    let id = UUID().uuidString
    let diagnosis: String = "即時型IgE抗体アレルギー"
    let diagnosisDate = Date()
    let diagnosedHospital: String = ""
    let diagnosedAllergist: String = ""
    let allergens: [String] = []
    
    let diagnosisInfo: [DiagnosisListModel] = []
    let record: CKRecord
}

@MainActor class DiagnosisModel: ObservableObject {
    
    @Published var diagnosis: String = ""
    @Published var diagnosisDate = Date()
    @Published var diagnosedHospital: String = ""
    @Published var diagnosedAllergist: String = ""
    @Published var allergens: [String] = []
    
    @Published var diagnosisInfo: [DiagnosisListModel] = []
    let record: CKRecord
    var isUpdated: Bool = false
    
    init(record: CKRecord) {
        self.record = record
        fetchItemsFromCloud()
    }
    
    init(diagnosis: CKRecord) {
        record = diagnosis
        guard let diagnosis = record["diagnosis"] as? String,
              let diagnosisDate = record["diagnosisDate"] as? Date,
              let allergens = record["allergens"] as? [String] else {
            return
        }
        let diagnosedHospital = record["diagnosedHospital"] as? String
        let diagnosedAllergist = record["diagnosedAllergist"] as? String
        
        self.diagnosis = diagnosis
        self.diagnosisDate = diagnosisDate
        self.allergens = allergens
        self.diagnosedHospital = diagnosedHospital ?? ""
        self.diagnosedAllergist = diagnosedAllergist ?? ""
        isUpdated = true
    }
    //MARK: - Saving to Private DataBase Custom Zone
    
    func addButtonPressed() {
        /// Gender, Birthdate are not listed on 'guard' since they have already values
        guard !allergens.isEmpty else { return }
        if isUpdated {
            updateItem()
        } else {
            addItem(
                record: record,
                diagnosis: diagnosis,
                diagnosisDate: diagnosisDate,
                diagnosedHospital: diagnosedHospital,
                diagnosedAllergist: diagnosedAllergist,
                allergens: allergens)
        }
    }
    
    private func addItem(
        record: CKRecord,
        diagnosis: String,
        diagnosisDate: Date,
        diagnosedHospital: String?,
        diagnosedAllergist: String?,
        allergens: [String]
        ) {
            
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "DiagnosisInfo", recordID: ckRecordID)

            myRecord["diagnosis"] = diagnosis
            myRecord["diagnosisDate"] = diagnosisDate
            myRecord["diagnosedHospital"] = diagnosedHospital
            myRecord["diagnosedAllergist"] = diagnosedAllergist
            myRecord["allergens"] = allergens
            let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            myRecord["profile"] = reference as CKRecordValue
            saveItem(record: myRecord)
        }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
            if let record = returnedRecord {
                DispatchQueue.main.async {
                   NotificationCenter.default.post(name: NSNotification.Name.init("removeDiagnosis"), object: DiagnosisListModel(record: record))
                }
            }
        }
    }
    
    //MARK: - Fetching from CK Private DataBase Custom Zone
    
    func fetchItemsFromCloud() {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "profile == %@", reference)
        
        let query = CKQuery(recordType: "DiagnosisInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)

        self.diagnosisInfo = []
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let member = DiagnosisListModel(record: returnedRecord) {
                    self.diagnosisInfo.append(member)
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED DiagnosisInfo queryResultBlock")
        }
        addOperation(operation: queryOperation)
    }
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    //MARK: - UPDATE/EDIT @CK Private DataBase Custom Zone
        
    func updateItem() {
        let myRecord = record

        myRecord["diagnosisDate"] = diagnosisDate
        myRecord["diagnosedHospital"] = diagnosedHospital
        myRecord["diagnosedAllergist"] = diagnosedAllergist
        myRecord["allergens"] = allergens
        saveItem(record: myRecord)
    }
    
    
    //MARK: - DELETE CK @CK Private DataBase Custom Zone

    func deleteItemsFromCloud(completion: @escaping ((Bool) -> Void)) {
        CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { recordID, error in
            DispatchQueue.main.async {
                completion(error == nil)
                if error == nil {
                    NotificationCenter.default.post(name: NSNotification.Name.init("removeDiagnosis"), object: nil)
                }
            }
        }
    }
    
}

