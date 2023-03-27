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

struct episodeInfoModel: Identifiable {
    let id = UUID().uuidString
    let data: Data? //image
    let episodeDate: Date
    let firstKnownExposure: Bool = false
    let wentToHospital: Bool = false
    let typeOfExposure: [String] = []
    let symptoms: [String] = []
    let leadTimeToSymptoms: String = ""
    let treatments: [String] = []
    let otherTreatment: String = ""
    let episodePhoto: Image?
    let episodeInfoModel: [EpisodeDetails] = []
    let record: CKRecord
}

@MainActor class EpisodeModel: ObservableObject {
  
    // MARK: - Profile Properties
    
    @Published var episodeDate: Date = Date()
    @Published var firstKnownExposure: Bool = false
    @Published var wentToHospital: Bool = false
    @Published var typeOfExposure: [String] = []
    @Published var symptoms: [String] = []
    @Published var skinSymptoms: [String] = []
    @Published var leadTimeToSymptoms: String = ""
    @Published var treatments: [String] = []
    @Published var otherTreatment: String = ""
    @Published var episodePhoto: [EpisodePhoto]  = []
    @Published var episodeInfoModel: [EpisodeDetails] = []

    @Published var symptomCategories = ["皮膚・粘膜", "呼吸器", "循環器", "Abdominal", "その他"]
    @Published var typeOfExposureOptions = ["摂取", "肌に触れた", "匂い", "不明"]
    @Published var leadTimeToSymptomsOptions = ["Under 5 min", "5-10 min", "10-15 min", "15-30 min", "30-60 min", "Over an hour"]
    @Published var treatmentsOptions = ["Antihistamine", "Injected steroids", "Oral steroids", "Topical steroids", "Epinephrine shot in the muscle", "Albuterol inhaler", "Other"]
    
    init() {
        fetchItemsFromCloud()
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
    
    struct EpisodePhoto: Transferable {
        let image: Image
        let data: Data
        
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
                return EpisodePhoto(image: image, data: data)
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
        return imageSelection.loadTransferable(type: EpisodePhoto.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let episodePhoto?):
                    self.imageState = .success(episodePhoto.image)
                    self.episodePhoto.append(episodePhoto)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    //MARK: - Save an image as a CKAsset with CloudKit
    
    func getImageURL(for data:[EpisodePhoto]) -> [URL]? {
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
        guard !typeOfExposure.isEmpty else { return }
        guard !symptoms.isEmpty else { return }
        guard !leadTimeToSymptoms.isEmpty else { return }
        guard !treatments.isEmpty else { return }
        addItem(
            episodeDate: episodeDate,
            firstKnownExposure: firstKnownExposure,
            wentToHospital: wentToHospital,
            typeOfExposure: typeOfExposure,
            symptoms: symptoms,
            leadTimeToSymptoms: leadTimeToSymptoms,
            treatments: treatments,
            otherTreatment: otherTreatment,
            episodePhoto: getImageURL(for: episodePhoto))
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
        episodePhoto: [URL]?) {
            
            let ckRecordZoneID = CKRecordZone(zoneName: "Episode")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "EpisodeInfo", recordID: ckRecordID)
            if let episodePhoto = episodePhoto {
                let urls = episodePhoto.map { return CKAsset(fileURL: $0)
                }
                
                myRecord["episodePhoto"] = urls
            }
            myRecord["episodeDate"] = episodeDate
            myRecord["firstKnownExposure"] = firstKnownExposure
            myRecord["wentToHospital"] = wentToHospital
            myRecord["typeOfExposure"] = typeOfExposure
            myRecord["symptoms"] = symptoms
            myRecord["leadTimeToSymptoms"] = leadTimeToSymptoms
            myRecord["treatments"] = treatments
            myRecord["otherTreatment"] = otherTreatment
            saveItem(record: myRecord)
        }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
        }
    }
    
    
    //MARK: - Fetch from CK Private DataBase
    
    func fetchItemsFromCloud() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "episodeInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.recordFetchedBlock = { (returnedRecord) in
//            if let episodeDetails = EpisodeDetails(record: returnedRecord) {
//                self.episodeInfoModel.append(episodeDetails)
//            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED queryResultBlock")
//            DispatchQueue.main.async {
//                self?.profileInfo = returnedItems
//            }
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
}
