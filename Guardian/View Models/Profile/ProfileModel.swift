/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An observable state object that contains profile details.
*/

import SwiftUI
import PhotosUI
import CoreTransferable
import CloudKit

class NumbersOnly: ObservableObject {
    @Published var value = "" {
        didSet {
            let filtered = value.filter { $0.isNumber }
            
            if value != filtered {
                value = filtered
            }
        }
    }
}

@MainActor class ProfileModel: ObservableObject {
    
    //MARK: - Gender
    enum Gender: String, CaseIterable, Identifiable {
        case 男
        case 女
        case 選択なし
        var id: String { self.rawValue }
    }
    
    // MARK: - Profile Properties
    
    @Published var data: Data? //image
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var gender: Gender = .選択なし
    @Published var birthDate = Date()
    @Published var hospitalName: String = ""
    @Published var allergist: String = ""
    @Published var allergistContactInfo: String = ""
    @Published var profileInfo: [String] = []
    @Published var profileInfoImage: URL?
    
    init() {
        fetchItems()
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
            
//            let imageData:Data = image.jpegData(compressionQuality: 1.0)!
            let path:String = documentsDirectoryPath.appendingPathComponent(tempImageName)
//            try? image.jpegData(compressionQuality: 1.0)!.write(to: URL(fileURLWithPath: path), options: [.atomic])
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
        gender:Gender,
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
    
    //MARK: - Fetching to Private DataBase Custom Zone
    
    func fetchItems() {
        
        _ = Gender.RawValue()
        var returnedItems: [String] = []
        var returnedURL: URL?
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "ProfileInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        
        if #available(iOS 15.0, *) {
            queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
                switch returnedResult {
                case .success(let record) :
                    guard let firstName = record["firstName"] as? String else {return}
                    guard let lastName = record["lastName"] as? String else {return}
                    guard let gender = record["gender"] as? String else {return}
//                    guard let birthDate = record["birthDate"] as? String else {return}
                    guard let hospitalName = record["hospitalName"] as? String else {return}
                    guard let allergist = record["allergist"] as? String else {return}
                    guard let allergistContactInfo = record["allergistContactInfo"] as? String else {return}
                    if let profileImage = record["profileImage"] as? CKAsset {
                        returnedURL = profileImage.fileURL
                    }
                    returnedItems.append(firstName)
                    returnedItems.append(lastName)
                    returnedItems.append(gender)
//                    returnedItems.append(birthDate)
                    returnedItems.append(hospitalName)
                    returnedItems.append(allergist)
                    returnedItems.append(allergistContactInfo)
                    
                case .failure(let error) :
                    print("Error recordMatchedBlock: \(error)")
                }
            }
        } else {
            queryOperation.recordFetchedBlock = { (returnedRecord) in
                guard let firstName = returnedRecord["firstName"] as? String else {return}
                guard let lastName = returnedRecord["lastName"] as? String else {return}
                guard let gender = returnedRecord["gender"] as? String else {return}
//                guard let birthDate = returnedRecord["birthDate"] as? String else {return}
                guard let hospitalName = returnedRecord["hospitalName"] as? String else {return}
                guard let allergist = returnedRecord["allergist"] as? String else {return}
                guard let allergistContactInfo = returnedRecord["allergistContactInfo"] as? String else {return}
                if let profileImage = returnedRecord["profileImage"] as? CKAsset {
                    returnedURL = profileImage.fileURL
                }
                returnedItems.append(firstName)
                returnedItems.append(lastName)
                returnedItems.append(gender)
//                returnedItems.append(birthDate)
                returnedItems.append(hospitalName)
                returnedItems.append(allergist)
                returnedItems.append(allergistContactInfo)
            }
        }
        
        if #available(iOS 15.0, *) {
            queryOperation.queryResultBlock = { [weak self] returnedResult in
                print("RETURNED RESULT: \(returnedResult)")
                DispatchQueue.main.async {
                    self?.profileInfo = returnedItems
                    self?.profileInfoImage = returnedURL
                }
            }
        } else {
            queryOperation.queryCompletionBlock = { [weak self] (returnedCursor, returnedError) in
                print("RETURNED queryResultBlock")
                DispatchQueue.main.async {
                    self?.profileInfo = returnedItems
                    self?.profileInfoImage = returnedURL
                }
            }
        }
        
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
}
