//
//  DiagnosisModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/24.
//

import PhotosUI
import SwiftUI
import CoreTransferable
import CloudKit

struct diagnosisInfoModel: Hashable, Identifiable {
    let id = UUID().uuidString
    let diagnosis: String = "即時型IgE抗体アレルギー"
    let diagnosisDate = Date()
    let diagnosedHospital: String = ""
    let diagnosedAllergist: String = ""
    let diagnosedAllergistComment: String = ""
    let allergens: [String] = []
    
    let diagnosisInfo: [DiagnosisListModel] = []
    let record: CKRecord
}

@MainActor class DiagnosisModel: ObservableObject {
    
    @Published var diagnosis: String = ""
    @Published var diagnosisDate = Date()
    @Published var diagnosedHospital: String = ""
    @Published var diagnosedAllergist: String = ""
    @Published var diagnosedAllergistComment: String = ""
    @Published var allergens: [String] = []
    @Published var data: [Data] = []
    @Published var diagnosisImages: [DiagnosisImage] = []
    @Published var diagnosisInfo: [DiagnosisListModel] = []
    let record: CKRecord
    var isUpdated: Bool = false
    
    init(record: CKRecord) {
        self.record = record
    }
    
    init(diagnosis: CKRecord) {
        record = diagnosis
        guard let diagnosis = record["diagnosis"] as? String,
              let diagnosisDate = record["diagnosisDate"] as? Date,
              let allergens = record["allergens"] as? [String]
        else {
            return
        }
        let diagnosedHospital = record["diagnosedHospital"] as? String
        let diagnosedAllergist = record["diagnosedAllergist"] as? String
        let diagnosedAllergistComment = record["diagnosedAllergistComment"] as? String
        
        fetchStoredImages()
        
        self.diagnosis = diagnosis
        self.diagnosisDate = diagnosisDate
        self.allergens = allergens
        self.diagnosedHospital = diagnosedHospital ?? ""
        self.diagnosedAllergist = diagnosedAllergist ?? ""
        self.diagnosedAllergistComment = diagnosedAllergistComment ?? ""
        isUpdated = true
    }
    
    // MARK: - Diagnosis Image
    enum ImageState {
        case empty
        case loading(Progress)
        case success(Image)
        case failure(Error)
    }
    
    enum TransferError: Error {
        case importFailed
    }
    
    struct DiagnosisImage: Transferable {
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
                return DiagnosisPhoto(image: image, data: data)
#elseif canImport(UIKit)
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(uiImage: uiImage)
                return DiagnosisImage(image: image, data: data)
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
        return imageSelection.loadTransferable(type: DiagnosisImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let diagnosisPhoto?):
                    self.imageState = .success(diagnosisPhoto.image)
                    self.diagnosisImages = [diagnosisPhoto]
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    //MARK: - Save an image as a CKAsset with CloudKit
    
    func getImageURL(for data:[DiagnosisImage]) -> [URL]? {
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
    
    //MARK: - Saving to Private DataBase
    
    func addButtonPressed() {
        /// Gender, Birthdate are not listed on 'guard' since they have already values
        guard !allergens.isEmpty else { return }
        if isUpdated {
            updateDiagnosis()
        } else {
            addItem(
                record: record,
                diagnosis: diagnosis,
                diagnosisDate: diagnosisDate,
                diagnosedHospital: diagnosedHospital,
                diagnosedAllergist: diagnosedAllergist,
                diagnosedAllergistComment: diagnosedAllergistComment,
                allergens: allergens,
                diagnosisPhoto: getImageURL(for: diagnosisImages)
            )
        }
    }
    
    //MARK: - UPDATE/EDIT @CK Private DataBase
        
    func updateDiagnosis() {
        let myRecord = record
        if let diagnosisPhoto = getImageURL(for: diagnosisImages) {
            let urls = diagnosisPhoto.map { return CKAsset(fileURL: $0)
            }
            myRecord["data"] = urls
        }

        myRecord["diagnosisDate"] = diagnosisDate
        myRecord["diagnosedHospital"] = diagnosedHospital
        myRecord["diagnosedAllergist"] = diagnosedAllergist
        myRecord["diagnosedAllergistComment"] = diagnosedAllergistComment
        myRecord["allergens"] = allergens
        saveItem(record: myRecord)
    }
    
    
    private func addItem(
        record: CKRecord,
        diagnosis: String,
        diagnosisDate: Date,
        diagnosedHospital: String?,
        diagnosedAllergist: String?,
        diagnosedAllergistComment: String?,
        allergens: [String],
        diagnosisPhoto: [URL]?
    ) {
//            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
//            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "DiagnosisInfo")
            if let diagnosisPhoto = diagnosisPhoto {
                let urls = diagnosisPhoto.map { return CKAsset(fileURL: $0)
                }
                myRecord["data"] = urls
            }
            myRecord["diagnosis"] = diagnosis
            myRecord["diagnosisDate"] = diagnosisDate
            myRecord["diagnosedHospital"] = diagnosedHospital
            myRecord["diagnosedAllergist"] = diagnosedAllergist
            myRecord["diagnosedAllergistComment"] = diagnosedAllergistComment
            myRecord["allergens"] = allergens
            let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            myRecord["profile"] = reference as CKRecordValue
            saveItem(record: myRecord)
        }
    
    func updateRecord(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.modifyRecords(saving: [record], deleting: []) { result in
            
        }
    }
    
    func deleteRecord(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { _, _ in
            
        }
    }
    
    func deleteAllData() {
        for diagnosis in diagnosisInfo {
            deleteRecord(record: diagnosis.record)
        }
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
    
    func fetchItemsFromCloud(complete: (() ->Void)? = nil) {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "profile == %@", reference)
        
        let query = CKQuery(recordType: "DiagnosisInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.queuePriority = .veryHigh
        
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
            if let completion = complete {
                DispatchQueue.main.async {
                    completion()
                }
            }
            complete?()
        }
        addOperation(operation: queryOperation)
    }
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    func fetchStoredImages() {
        if let assets = record["data"] as? [CKAsset] {
            print("Number of assets: \(assets.count)") // Add this line
            for asset in assets {
                if let imageURL = asset.fileURL {
                    if let imageData = try? Data(contentsOf: imageURL) {
                        if let uiImage = UIImage(data: imageData) {
                            let image = Image(uiImage: uiImage)
                            let diagnosisImage = DiagnosisImage(image: image, data: imageData)
                            self.diagnosisImages.append(diagnosisImage)
                        }
                    }
                }
            }
        } else {
            print("No assets found.") // Add this line
        }
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

