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
    
    @Published var episodeDate: Date = Date()
    @Published var firstKnownExposure: Bool = false
    @Published var wentToHospital: Bool = false
    @Published var typeOfExposure: [String] = []
    @Published var symptoms: [String] = []
    @Published var skinSymptoms: [String] = []
    @Published var leadTimeToSymptoms: String = "5分以内"
    @Published var treatments: [String] = []
    @Published var otherTreatment: String = ""
    @Published var data: [Data] = []
    @Published var episodeImages: [EpisodeImage] = []
    @Published var episodeInfo: [EpisodeListModel] = []
    @Published var allergens: [AllergensListModel] = []
    
    @Published var symptomCategories = ["皮膚", "呼吸器", "循環器", "消化器", "その他"]
    @Published var typeOfExposureOptions = ["摂取", "肌に接触", "匂い", "不明"]
    @Published var leadTimeToSymptomsOptions = ["5分以内", "5~10分", "10~15分", "15~30分", "30~60分", "60分~"]
    @Published var treatmentsOptions = ["抗ヒスタミン薬", "ステロイド注入", "経口ステロイド", "ステロイド外用薬", "エピペン注入", "その他"]
    
    let record: CKRecord
    var isUpdated: Bool = false
    
    init(record: CKRecord) {
        self.record = record
        fetchAllergens()
    }
    
    init(episode: CKRecord) {
        record = episode
        guard let episodeDate = episode["episodeDate"] as? Date,
              let firstKnownExposure = episode["firstKnownExposure"] as? Bool,
              let wentToHospital = episode["wentToHospital"] as? Bool,
              let leadTimeToSymptoms = episode["leadTimeToSymptoms"] as? String
        else {
            return
        }
        let typeOfExposure = episode["typeOfExposure"] as? [String]
        let symptoms = episode["symptoms"] as? [String]
        let skinSymptoms = episode["skinSymptoms"] as? [String]
        let treatments = episode["treatments"] as? [String]
        let otherTreatment = episode["otherTreatment"] as? String
        
        fetchStoredImages()
        
        self.episodeDate = episodeDate
        self.firstKnownExposure = firstKnownExposure
        self.wentToHospital = wentToHospital
        self.typeOfExposure = typeOfExposure ?? [""]
        self.symptoms = symptoms ?? [""]
        self.skinSymptoms = skinSymptoms ?? [""]
        self.leadTimeToSymptoms = leadTimeToSymptoms
        self.treatments = treatments ?? [""]
        self.otherTreatment = otherTreatment ?? ""
        isUpdated = true
    }
    
    // MARK: - Profile Image
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
                symptoms: symptoms,
                leadTimeToSymptoms: leadTimeToSymptoms,
                treatments: treatments,
                otherTreatment: otherTreatment,
                episodePhoto: getImageURL(for: episodeImages)
            )
        }
    }
    
    //MARK: - UPDATE/EDIT @CK Private DataBase
    
    func updateEpisode() {
        let myRecord = record
        if let episodePhoto = getImageURL(for: episodeImages) {
            let urls = episodePhoto.map { return CKAsset(fileURL: $0)
            }
            myRecord["data"] = urls
        }
        myRecord["episodeDate"] = episodeDate
        myRecord["firstKnownExposure"] = firstKnownExposure
        myRecord["wentToHospital"] = wentToHospital
        myRecord["typeOfExposure"] = typeOfExposure
        myRecord["symptoms"] = symptoms
        myRecord["leadTimeToSymptoms"] = leadTimeToSymptoms
        myRecord["treatments"] = treatments
        myRecord["otherTreatment"] = otherTreatment
        updateRecord(record: myRecord)
    }
    
    private func addItem(
        episodeDate: Date,
        firstKnownExposure: Bool,
        wentToHospital: Bool,
        typeOfExposure: [String],
        symptoms: [String],
        leadTimeToSymptoms: String,
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
            myRecord["symptoms"] = symptoms
            myRecord["leadTimeToSymptoms"] = leadTimeToSymptoms
            myRecord["treatments"] = treatments
            myRecord["otherTreatment"] = otherTreatment
            let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            saveItem(record: myRecord)
            // Counting `totalNumberOfEpisodes`
            let totalNumberOfEpisodes = record["totalNumberOfEpisodes"] as? Int ?? 0
            let totalNumberOfMedicalTests = record["totalNumberOfMedicalTests"] as? Int ?? 0
            record["totalNumberOfEpisodes"]  = totalNumberOfEpisodes + 1
            updateRecord(record: record)
        }
    
    func updateRecord(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.modifyRecords(saving: [record], deleting: []) { result in

        }
    }
    
    func deleteRecord(record: CKRecord) {
        if record.recordType == "EpisodeInfo" {
            let allergen = record
            allergen["totalNumberOfEpisodes"] = episodeInfo.count - 1
            CKContainer.default().privateCloudDatabase.modifyRecords(saving: [allergen], deleting: []) { result in
            }
        }
        CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { _, _ in
            
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
        }
    }
    
    
    //MARK: - Fetch from CK Private DataBase
    
    func fetchItemsFromCloud(complete: @escaping () -> Void) {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)
        
        let query = CKQuery(recordType: "EpisodeInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.queuePriority = .veryHigh
        
        DispatchQueue.main.async {
            self.episodeInfo = []
        }
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
        queryOperation.queuePriority = .veryHigh

        self.allergens = []
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = AllergensListModel(record: returnedRecord) {
                    self.allergens.append(object)
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED Allergens queryResultBlock")
        }
        addOperation(operation: queryOperation)
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
