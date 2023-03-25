//ProfileModel.swift

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
    let profileInfo: [MemberList] = []
    let record: CKRecord
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
    @Published var profileInfo: [MemberList] = []
    @Published var isAddMemberPresented = false
    @Published var isEditMemberPresented = false
    
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
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "ProfileInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            if let member = MemberList(record: returnedRecord) {
                self.profileInfo.append(member)
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
    

    
    func updateItem(model: MemberList) {
        
    }
    
    
    //MARK: - DELETE CK @CK Private DataBase Custom Zone

    func deleteItemsFromCloud(indexSet: IndexSet) {
        
    }
    
}
