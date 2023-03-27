//ProfileModel.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI
import PhotosUI
import CoreTransferable
import CloudKit

struct profileInfoModel: Hashable, Identifiable {
    let id = UUID().uuidString
    let data: Data? //image
    let firstName: String = ""
    let lastName: String = ""
    let gender: Gender = .選択なし
    let birthDate = Date()
    let hospitalName: String = ""
    let allergist: String = ""
    let allergistContactInfo: String = ""
    let allergens: [String] = []
    let profileInfo: [MemberListModel] = []
    let record: CKRecord
}

@MainActor class ProfileModel: ObservableObject  {
    enum Gender: String, CaseIterable, Identifiable {
        case 男性, 女性, 選択なし
        var id: String { self.rawValue }
    }

    @Published var data: Data? //image
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var gender: Gender = .選択なし
    @Published var birthDate = Date()
    @Published var hospitalName: String = ""
    @Published var allergist: String = ""
    @Published var allergistContactInfo: String = ""
    @Published var allergens: [String] = []
    @Published var profileInfo: [MemberListModel] = []
    @Published var isAddMemberPresented = false
    @Published var isEditMemberPresented = false
    let record: CKRecord
    var isUpdated: Bool = false
    
    init(record: CKRecord) {
        self.record = record
        fetchItemsFromCloud()
    }
    init(profile: CKRecord) {
        record = profile
        guard let firstName = record["firstName"] as? String,
              let lastName = record["lastName"] as? String,
              let birthDate = record["birthDate"] as? Date,
              let gender = (record["gender"] as? String),
              let genderEnum = Gender(rawValue: gender),
              let allergens = record["allergens"] as? [String] else {
            return
        }
        let hospitalName = record["hospitalName"] as? String
        let allergist = record["allergist"] as? String
        let allergistContactInfo = record["allergistContactInfo"] as? String
        
        if let asset = record["profileImage"] as? CKAsset, let url = asset.fileURL {
            let imageURL = try? Data(contentsOf: url)
            self.data = imageURL
        } else {
            print("No Image File")
        }
        self.firstName = firstName
        self.lastName = lastName
        self.allergens = allergens
        self.gender = genderEnum
        self.birthDate = birthDate
        self.hospitalName = hospitalName ?? ""
        self.allergist = allergist ?? ""
        self.allergistContactInfo = allergistContactInfo ?? ""
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
    
    struct ProfileImage: Transferable {
        let image: Image
        let data: Data
        
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(importedContentType: .image) { data in
                #if canImport(AppKit)
                guard let nsImage = NSImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(nsImage: nsImage)
                return ProfileImage(image: image, data: data)
                #elseif canImport(UIKit)
                guard let uiImage = UIImage(data: data) else {
                    throw TransferError.importFailed
                }
                let image = Image(uiImage: uiImage)
                return ProfileImage(image: image, data: data)
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
        return imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage?):
                    self.imageState = .success(profileImage.image)
                    self.data = profileImage.data
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    //MARK: - Save an image as a CKAsset with CloudKit
    
    func getImageURL(for data: Data?) -> URL? {
        let documentsDirectoryPath:NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let tempImageName = "tempImage.jpg"
        var imageURL: URL?
        
        if let data = data {
            let path:String = documentsDirectoryPath.appendingPathComponent(tempImageName)
            imageURL = URL(fileURLWithPath: path)
            try? data.write(to: imageURL!, options: [.atomic])
        }
        return imageURL
    }
    
    //MARK: - Saving to Private DataBase Custom Zone
    
    func addButtonPressed() {
        /// Gender, Birthdate are not listed on 'guard' since they have already values
        guard !firstName.isEmpty, !lastName.isEmpty else { return }
        addItem(
            profileImage: getImageURL(for: data),
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            birthDate: birthDate,
            hospitalName: hospitalName,
            allergist: allergist,
            allergistContactInfo: allergistContactInfo)
    }
    
    private func addItem(
        profileImage: URL?,
        firstName: String,
        lastName: String,
        gender: Gender,
        birthDate: Date,
        hospitalName: String,
        allergist: String,
        allergistContactInfo: String ) {
            
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "ProfileInfo", recordID: ckRecordID)
            if let profileImage = profileImage {
                let url = CKAsset(fileURL: profileImage)
                myRecord["profileImage"] = url
            }
            myRecord["firstName"] = firstName
            myRecord["lastName"] = lastName
            myRecord["gender"] = gender.rawValue
            myRecord["birthDate"] = birthDate
            myRecord["hospitalName"] = hospitalName
            myRecord["allergist"] = allergist
            myRecord["allergistContactInfo"] = allergistContactInfo
            saveItem(record: myRecord)
        }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
        }
    }
    
    //MARK: - Fetching from CK Private DataBase Custom Zone
    
    func fetchItemsFromCloud() {
        let reference = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "profile == %@", reference)
        
        let query = CKQuery(recordType: "ProfileInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)
        
        self.profileInfo = []
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let member = MemberListModel(record: returnedRecord) {
                    self.profileInfo.append(member)
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED queryResultBlock")
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    //MARK: - UPDATE/EDIT @CK Private DataBase Custom Zone
    

    
    func updateItem(model: MemberListModel) {
        let myRecord = record
        
        myRecord["profileImage"] = data
        myRecord["firstName"] = firstName
        myRecord["lastName"] = lastName
        myRecord["gender"] = gender.rawValue
        myRecord["birthDate"] = birthDate
        myRecord["hospitalName"] = hospitalName
        myRecord["allergist"] = allergist
        myRecord["allergistContactInfo"] = allergistContactInfo
        saveItem(record: myRecord)
    }
    
    
    //MARK: - DELETE CK @CK Private DataBase Custom Zone

    func deleteItemsFromCloud(indexSet: IndexSet) {
        
    }
    
}
