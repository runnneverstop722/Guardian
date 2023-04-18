//
//  EpisodeModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/24.
//

import PhotosUI
import SwiftUI
import CoreTransferable
import CloudKit

@MainActor class EpisodeModel: ObservableObject {
    
    // MARK: - Episode Properties
    private let context = PersistenceController.shared.container.viewContext
    
    @Published var episodeDate: Date = Date()
    @Published var firstKnownExposure: Bool = false
    @Published var wentToHospital: Bool = false
    @Published var typeOfExposure: [String] = []
    @Published var intakeAmount: String = ""
    @Published var symptoms: [String] = []
    @Published var severity: String = ""
    @Published var skinSymptoms: [String] = []
    @Published var leadTimeToSymptoms: String = "5分以内"
    @Published var didExercise: Bool = false
    @Published var treatments: [String] = []
    @Published var otherTreatment: String = ""
    @Published var data: [Data] = []
    @Published var episodeImages: [EpisodeImage] = []
    @Published var episodeInfo: [EpisodeListModel] = []
    @Published var allergens: [AllergensListModel] = []
    
    @Published var symptomCategories = ["皮膚", "粘膜", "消化器", "呼吸器", "循環器", "神経"]
    @Published var typeOfExposureOptions = ["摂取", "肌に接触", "匂い", "不明"]
    @Published var leadTimeToSymptomsOptions = ["5分以内", "5~10分", "10~15分", "15~30分", "30~60分", "60分~"]
    @Published var treatmentsOptions = ["抗ヒスタミン薬", "ステロイド注入", "経口ステロイド", "ステロイド外用薬", "エピペン注入", "その他"]
    
    let record: CKRecord
    let allergen: CKRecord
    var isUpdated: Bool = false
    
    func selectExposureType(_ type: String) {
            if type == "不明" {
                typeOfExposure = ["不明"]
            } else {
                if let index = typeOfExposure.firstIndex(of: "不明") {
                    typeOfExposure.remove(at: index)
                }
                if !typeOfExposure.contains(type) {
                    typeOfExposure.append(type)
                } else {
                    if let index = typeOfExposure.firstIndex(of: type) {
                        typeOfExposure.remove(at: index)
                    }
                }
            }
        }
    func judgeSeverity() {
        if symptoms.contains(where: { $0.contains("🔴") }) {
            severity = "重症"
        } else if symptoms.contains(where: { $0.contains("🟠") }) {
            severity = "中等症"
        } else if symptoms.contains(where: { $0.contains("🟡") }) {
            severity = "軽症"
        } else {
            severity = ""
        }
    }
    func displaySeverity() -> String {
        switch severity {
        case "重症":
            return "🔴重症のアレルギー症状あり"
        case "中等症":
            return "🟠中等症のアレルギー症状あり"
        case "軽症":
            return "🟡軽症のアレルギー症状あり"
        default:
            return ""
        }
    }
    
    init(record: CKRecord) {
        self.allergen = record
        self.record = record
        fetchAllergenFromLocalCache()
        fetchAllergens()
    }
    
    init(allergen: CKRecord, episode: CKRecord) {
        self.allergen = allergen
        record = episode
        guard let episodeDate = episode["episodeDate"] as? Date,
              let firstKnownExposure = episode["firstKnownExposure"] as? Bool,
              let wentToHospital = episode["wentToHospital"] as? Bool,
              let leadTimeToSymptoms = episode["leadTimeToSymptoms"] as? String,
              let didExercise = episode["didExercise"] as? Bool
        else {
            return
        }
        let typeOfExposure = episode["typeOfExposure"] as? [String]
        let intakeAmount = episode["intakeAmount"] as? String
        let symptoms = episode["symptoms"] as? [String]
        let severity = episode["severity"] as? String
        let skinSymptoms = episode["skinSymptoms"] as? [String]
        let treatments = episode["treatments"] as? [String]
        let otherTreatment = episode["otherTreatment"] as? String
        
        fetchStoredImages()
        
        self.episodeDate = episodeDate
        self.firstKnownExposure = firstKnownExposure
        self.wentToHospital = wentToHospital
        self.typeOfExposure = typeOfExposure ?? [""]
        self.intakeAmount = intakeAmount ?? ""
        self.symptoms = symptoms ?? [""]
        self.severity = severity ?? ""
        self.skinSymptoms = skinSymptoms ?? [""]
        self.leadTimeToSymptoms = leadTimeToSymptoms
        self.didExercise = didExercise
        self.treatments = treatments ?? [""]
        self.otherTreatment = otherTreatment ?? ""
        isUpdated = true
    }
    
    // MARK: - Episode Images
    enum ImageState {
        case empty
        case loading(Progress)
        case success(Image)
        case failure(Error)
    }
    
    enum TransferError: Error {
        case importFailed
    }
    
    struct EpisodeImage: Transferable {
        let image: Image
        let data: Data
        var id = UUID()
        
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
#if canImport(AppKit)
                guard let nsImage = NSImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(nsImage: nsImage)
                return EpisodePhoto(image: image, data: data)
#elseif canImport(UIKit)
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(uiImage: uiImage)
                return EpisodeImage(image: image, data: data)
#else
                throw TransferError.importFailed
#endif
            }
        }
    }
    
    @Published private(set) var imageState: ImageState = .empty
    
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    // Private Methods
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: EpisodeImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let episodePhoto?):
                    self.imageState = .success(episodePhoto.image)
                    self.episodeImages = [episodePhoto]
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    //MARK: - Save an image as a CKAsset with CloudKit
    
    func getImageURL(for data:[EpisodeImage]) -> [URL]? {
        var imageURLs = [URL]()
        if data.isEmpty { return nil }
        for image in data {
            
            let documentsDirectoryPath:NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let tempImageName = String(format: "%@.jpg", UUID().uuidString)
            let path:String = documentsDirectoryPath.appendingPathComponent(tempImageName)
            //            try? image.jpegData(compressionQuality: 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            let imageURL = URL(fileURLWithPath: path)
            try? image.data.write(to: imageURL, options: [.atomic])
            imageURLs.append(imageURL)
        }
        return imageURLs
    }
    
    //MARK: - Saving to CK Private DataBase
    
    func addButtonPressed() {
        /// Gender, Birthdate are not listed on 'guard' since they have already values
        guard !leadTimeToSymptoms.isEmpty else { return }
        if isUpdated {
            updateEpisode()
        } else {
            addItem(
                episodeDate: episodeDate,
                firstKnownExposure: firstKnownExposure,
                wentToHospital: wentToHospital,
                typeOfExposure: typeOfExposure,
                intakeAmount: intakeAmount,
                symptoms: symptoms,
                severity: severity,
                leadTimeToSymptoms: leadTimeToSymptoms,
                didExercise: didExercise,
                treatments: treatments,
                otherTreatment: otherTreatment,
                episodePhoto: getImageURL(for: episodeImages)
            )
        }
    }
    
    //MARK: - UPDATE/EDIT @CK Private DataBase
    func updateEpisode() {
        let myRecord = record
        CKContainer.default().privateCloudDatabase.fetch(withRecordID: myRecord.recordID) {  record, _ in
            guard let record = record else { return }
            DispatchQueue.main.sync {
                self.updateEpisode(record: record)
            }
        }
    }
    func updateEpisode(record: CKRecord) {
        if let episodePhoto = getImageURL(for: episodeImages) {
            let urls = episodePhoto.map { return CKAsset(fileURL: $0)
            }
            record["data"] = urls
        }
        record["episodeDate"] = episodeDate
        record["firstKnownExposure"] = firstKnownExposure
        record["wentToHospital"] = wentToHospital
        record["typeOfExposure"] = typeOfExposure
        record["intakeAmount"] = intakeAmount
        record["symptoms"] = symptoms
        record["severity"] = severity
        record["leadTimeToSymptoms"] = leadTimeToSymptoms
        record["didExercise"] = didExercise
        record["treatments"] = treatments
        record["otherTreatment"] = otherTreatment
        saveItem(record: record)
    }
    
    private func addItem(
        episodeDate: Date,
        firstKnownExposure: Bool,
        wentToHospital: Bool,
        typeOfExposure: [String],
        intakeAmount: String,
        symptoms: [String],
        severity: String,
        leadTimeToSymptoms: String,
        didExercise: Bool,
        treatments: [String],
        otherTreatment: String,
        episodePhoto: [URL]?
    ) {
//            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
//            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "EpisodeInfo")
            if let episodePhoto = episodePhoto {
                let urls = episodePhoto.map { return CKAsset(fileURL: $0)
                }
                myRecord["data"] = urls
            }
            myRecord["episodeDate"] = episodeDate
            myRecord["firstKnownExposure"] = firstKnownExposure
            myRecord["wentToHospital"] = wentToHospital
            myRecord["typeOfExposure"] = typeOfExposure
            myRecord["intakeAmount"] = intakeAmount
            myRecord["symptoms"] = symptoms
            myRecord["severity"] = severity
            myRecord["leadTimeToSymptoms"] = leadTimeToSymptoms
            myRecord["didExercise"] = didExercise
            myRecord["treatments"] = treatments
            myRecord["otherTreatment"] = otherTreatment
            let reference = CKRecord.Reference(recordID: allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            saveItem(record: myRecord)
            // Counting `totalNumberOfEpisodes`
            let totalNumberOfEpisodes = allergen["totalNumberOfEpisodes"] as? Int ?? 0
            allergen["totalNumberOfEpisodes"]  = totalNumberOfEpisodes + 1
            updateRecord(record: allergen)
            NotificationCenter.default.post(name: NSNotification.Name.init("existingAllergenData"), object: AllergensListModel(record: allergen))
            PersistenceController.shared.addAllergen(allergen: allergen)
        }
    
    func updateRecord(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.modifyRecords(saving: [record], deleting: []) { result in

        }
    }
    
    func deleteRecord(record: CKRecord) {
        if record.recordType == "EpisodeInfo" {
            allergen["totalNumberOfEpisodes"] = max(episodeInfo.count - 1, 0)
            CKContainer.default().privateCloudDatabase.modifyRecords(saving: [allergen], deleting: []) { result in
            }
            PersistenceController.shared.addAllergen(allergen: allergen)
            NotificationCenter.default.post(name: NSNotification.Name.init("existingAllergenData"), object: AllergensListModel(record: allergen))
            PersistenceController.shared.deleteEpisode(recordID: record.recordID.recordName)
        }
        CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { recordID, error in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name.init("existingEpisodeData"), object: recordID)
                }
            }
        }
    }
    
    func deleteAllData() {
        for episode in episodeInfo {
            deleteRecord(record: episode.record)
        }
        if record.recordType == "EpisodeInfo" {
            let allergen = record
            allergen["totalNumberOfEpisodes"] = 0
            CKContainer.default().privateCloudDatabase.modifyRecords(saving: [allergen], deleting: []) { result in
                
            }
        }
    }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
            if let record = returnedRecord {
                DispatchQueue.main.async {
                   NotificationCenter.default.post(name: NSNotification.Name.init("existingEpisodeData"), object: EpisodeListModel(record: record))
                    PersistenceController.shared.addEpisode(record: record)
                }
            }
        }
    }
    
    
    //MARK: - Fetch from CK Private DataBase
    
    func fetchItemsFromCloud(complete: @escaping () -> Void) {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)
        
        let query = CKQuery(recordType: "EpisodeInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let episodeItem = EpisodeListModel(record: returnedRecord) {
                    self.episodeInfo.append(episodeItem)
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED EpisodeInfo queryResultBlock")
            DispatchQueue.main.async {
                complete()
            }
        }

        addOperation(operation: queryOperation)
    }
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    private func fetchAllergens() {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "profile == %@", reference)
        
        let query = CKQuery(recordType: "Allergens", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)

        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async { [self] in
                if let object = AllergensListModel(record: returnedRecord) {
                    let existedObject = self.allergens.first(where: { $0.record.recordID == returnedRecord.recordID
                    })
                    if existedObject == nil {
                        self.allergens.append(object)
                        PersistenceController.shared.addAllergen(allergen: returnedRecord)
                    }
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED Allergens queryResultBlock")
        }
        addOperation(operation: queryOperation)
    }
    func fetchItemsFromLocalCache() {
        let fetchRequest = EpisodeEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "allergenID == %@", record.recordID.recordName)
        do {
            let records = try context.fetch(fetchRequest)
            for record in records {
                if let object = EpisodeListModel(entity: record) {
                    self.episodeInfo.append(object)
                }
            }
        } catch let error as NSError {
            print("Could not fetch from local cache. \(error), \(error.userInfo)")
        }
    }
    func fetchAllergenFromLocalCache() {
        let fetchRequest = AllergenEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "profileID == %@", record.recordID.recordName)
        do {
            let records = try context.fetch(fetchRequest)
            for record in records {
                if let object = AllergensListModel(entity: record) {
                    self.allergens.append(object)
                }
            }
        } catch let error as NSError {
            print("Could not fetch from local cache. \(error), \(error.userInfo)")
        }
    }
    
    func fetchStoredImages() {
        if let assets = record["data"] as? [CKAsset] {
            print("Number of assets: \(assets.count)") // Add this line
            for asset in assets {
                if let imageURL = asset.fileURL {
                    if let imageData = try? Data(contentsOf: imageURL) {
                        if let uiImage = UIImage(data: imageData) {
                            let image = Image(uiImage: uiImage)
                            let episodeImage = EpisodeImage(image: image, data: imageData)
                            self.episodeImages.append(episodeImage)
                        }
                    }
                }
            }
        } else {
            print("No assets found.") // Add this line
        }
    }
}
