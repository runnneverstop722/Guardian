//
//  AllergenDetailViewModel.swift
//  Guardian
//
//  Created by Teff on 2023/05/07.
//

import SwiftUI
import CloudKit
import Combine

@MainActor class AllergenDetailViewModel: ObservableObject {
    @Published var episodeModel: EpisodeModel
    @Published var medicalTest: MedicalTest
    @Published var diagnosis = [DiagnosisListModel]()
    @Published var isLoading = true
    @Published var viewDidLoad = false
    @Published var showAlert = false
    @Published var showMedicalTestView = false
    @Published var showEpisodeView = false
    @Published var firstKnownExposure: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    let allergen: CKRecord
    var allergenName: String = "Unknown Allergen"
    init(allergen: CKRecord) {
        self.allergen = allergen
        allergenName = allergen["allergen"] as? String ?? ""
        medicalTest = MedicalTest(allergen: allergen)
        episodeModel = EpisodeModel(record: allergen)
    }
    func fetchLocalData() {
        let allergenID = medicalTest.allergen.recordID.recordName
        medicalTest.bloodTest = PersistenceController.shared.fetchBloodTest(allergenID: allergenID).compactMap({
            BloodTest(entity: $0)
        })
        medicalTest.skinTest = PersistenceController.shared.fetchSkinTest(allergenID: allergenID).compactMap({
            SkinTest(entity: $0)
        })
        medicalTest.oralFoodChallenge = PersistenceController.shared.fetchOralFoodChallenge(allergenID: allergenID).compactMap({
            OralFoodChallenge(entity: $0)
        })
        if let profileID = (medicalTest.allergen["profile"] as? CKRecord.Reference)?.recordID.recordName {
            diagnosis = PersistenceController.shared.fetchDiagnosis(profileID: profileID, allergen: allergenName).compactMap({
                DiagnosisListModel(entity: $0)
            })
        }
    }
    private func fetchData() {
        fetchLocalData()
        let dispatchWork = DispatchGroup()
        let reference = CKRecord.Reference(recordID: medicalTest.allergen.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)
        
        //MARK: - Blood
        let bloodTestQuery = CKQuery(recordType: "BloodTest", predicate: predicate)
        bloodTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let bloodTestQueryOperation = CKQueryOperation(query: bloodTestQuery)
        dispatchWork.enter()
        
        bloodTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = BloodTest(record: returnedRecord) {
                    let isExist = self.medicalTest.bloodTest.contains { $0.record?.recordID == object.record?.recordID
                    }
                    if !isExist {
                        self.medicalTest.bloodTest.append(object)
                    }
                }
            }
        }
        bloodTestQueryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.medicalTest.bloodTest = self.medicalTest.bloodTest.sorted(by: { item1, item2 in
                        return item1.bloodTestDate.compare(item2.bloodTestDate) == .orderedDescending
                    })
                case .failure(let error):
                    print("Error fetching Blood Test: \(error.localizedDescription)")
                }
                dispatchWork.leave()
            }
        }
        addOperation(operation: bloodTestQueryOperation)
        
        //MARK: - Skin
        let skinTestQuery = CKQuery(recordType: "SkinTest", predicate: predicate)
        skinTestQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let skinTestQueryOperation = CKQueryOperation(query: skinTestQuery)
        dispatchWork.enter()
        
        skinTestQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = SkinTest(record: returnedRecord) {
                    let isExist = self.medicalTest.skinTest.contains { $0.record?.recordID == object.record?.recordID
                    }
                    if !isExist {
                        self.medicalTest.skinTest.append(object)
                    }
                }
            }
        }
        skinTestQueryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.medicalTest.skinTest = self.medicalTest.skinTest.sorted(by: { item1, item2 in
                        return item1.skinTestDate.compare(item2.skinTestDate) == .orderedDescending
                    })
                case .failure(let error):
                    print("Error fetching Skin Test: \(error.localizedDescription)")
                }
                dispatchWork.leave()
            }
        }
        addOperation(operation: skinTestQueryOperation)
        
        //MARK: - OFC
        dispatchWork.enter()
        let OFCQuery = CKQuery(recordType: "OralFoodChallenge", predicate: predicate)
        OFCQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let OFCQueryOperation = CKQueryOperation(query: OFCQuery)
        
        OFCQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = OralFoodChallenge(record: returnedRecord) {
                    let isExist = self.medicalTest.oralFoodChallenge.contains { $0.record?.recordID == object.record?.recordID
                    }
                    if !isExist {
                        self.medicalTest.oralFoodChallenge.append(object)
                    }
                }
            }
        }
        OFCQueryOperation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.medicalTest.oralFoodChallenge = self.medicalTest.oralFoodChallenge.sorted(by: { item1, item2 in
                        return item1.oralFoodChallengeDate.compare(item2.oralFoodChallengeDate) == .orderedDescending
                    })
                case .failure(let error):
                    print("Error fetching OFC: \(error.localizedDescription)")
                }
                dispatchWork.leave()
            }
        }
        addOperation(operation: OFCQueryOperation)
        episodeModel.fetchItemsFromLocalCache()
        dispatchWork.enter()
        episodeModel.fetchItemsFromCloud {
            dispatchWork.leave()
        }
        dispatchWork.notify(queue: DispatchQueue.main) {
            self.isLoading = false
        }
    }
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
}
