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
import CoreData

@MainActor class ProfileModel: ObservableObject  {
    enum Gender: String, CaseIterable, Identifiable {
        case 男, 女, 選択なし
        var id: String { self.rawValue }
    }
    private let context = PersistenceController.shared.container.viewContext

    @Published var data: Data? //image
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var gender: Gender = .選択なし
    @Published var birthDate = Date()
    @Published var hospitalName: String = ""
    @Published var allergist: String = ""
    @Published var allergistContactInfo: String = ""
    @Published var allergens: [String] = []
    
    private var allergensObject: [AllergensModel] = []
    @Published var profileInfo: [MemberListModel] = []
    @Published var isAddMemberPresented = false
    @Published var isEditMemberPresented = false
    var record: CKRecord?
    var isUpdated: Bool = false
    
    init() {
        fetchItemsFromLocalCache()
        fetchItemsFromCloud()
    }
    init(profile: CKRecord) {
        record = profile
        guard let firstName = profile["firstName"] as? String,
              let lastName = profile["lastName"] as? String,
              let birthDate = profile["birthDate"] as? Date,
              let gender = (profile["gender"] as? String),
              let genderEnum = Gender(rawValue: gender)
        else {
            return
        }
        //        let allergens = profile["allergens"] as? [String] ?? []
        let hospitalName = profile["hospitalName"] as? String
        let allergist = profile["allergist"] as? String
        let allergistContactInfo = profile["allergistContactInfo"] as? String
        
        if let asset = profile["profileImage"] as? CKAsset, let url = asset.fileURL {
            let imageURL = try? Data(contentsOf: url)
            self.data = imageURL
            self.imageState = .success(Image(uiImage: UIImage(data: imageURL!)!))
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
        fetchAllergens(recordID: record!.recordID)
    }
    
    func fetchItemsFromLocalCache() {
            let fetchRequest = NSFetchRequest<ProfileInfoEntity>(entityName: "ProfileInfoEntity")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

            do {
                let localProfileInfo = try context.fetch(fetchRequest)
                self.profileInfo = localProfileInfo.compactMap { MemberListModel(entity: $0) }
            } catch let error as NSError {
                print("Could not fetch from local cache. \(error), \(error.userInfo)")
            }
        }

        func saveToLocalCache(_ profileInfo: MemberListModel) {
            let entity = ProfileInfoEntity(context: context)
            entity.update(with: profileInfo.record)

            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save to local cache. \(error), \(error.userInfo)")
            }
        }

        func deleteFromLocalCache(_ profileInfo: MemberListModel) {
            let fetchRequest = NSFetchRequest<ProfileInfoEntity>(entityName: "ProfileInfoEntity")
            fetchRequest.predicate = NSPredicate(format: "recordID == %@", profileInfo.record.recordID.recordName)

            do {
                let fetchedItems = try context.fetch(fetchRequest)
                if let itemToDelete = fetchedItems.first {
                    context.delete(itemToDelete)
                    try context.save()
                }
            } catch let error as NSError {
                print("Could not delete from local cache. \(error), \(error.userInfo)")
            }
        }
    
    private func fetchAllergens(recordID: CKRecord.ID) {
        let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "profile == %@", reference)
        
        let query = CKQuery(recordType: "Allergens", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.queuePriority = .veryHigh
        
        self.allergens = []
        self.allergensObject = []
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = AllergensModel(record: returnedRecord) {
                    self.allergens.append(object.allergen)
                    self.allergensObject.append(object)
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED DiagnosisInfo queryResultBlock")
        }
        addOperation(operation: queryOperation)
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
        guard !firstName.isEmpty, !lastName.isEmpty else { return }
        if isUpdated {
            updateItem()
        } else {
            addItem(
                profileImage: getImageURL(for: data),
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                birthDate: birthDate,
                hospitalName: hospitalName,
                allergist: allergist,
                allergistContactInfo: allergistContactInfo,
                allergens: allergens)
        }
    }
    
    private func addItem(
        profileImage: URL?,
        firstName: String,
        lastName: String,
        gender: Gender,
        birthDate: Date,
        hospitalName: String,
        allergist: String,
        allergistContactInfo: String,
        allergens: [String]
    )
    {
        
//        let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
//        let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
        let myRecord = CKRecord(recordType: "ProfileInfo")
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
        saveItem(record: myRecord) { [weak self] recordID in
            guard let id = recordID else { return }
            self?.updateSaveAllergens(recordID: id, allergens: allergens)
        }
    }
    
    private func deleteAllergens(recordID: CKRecord.ID) {
        
        CKContainer.default().privateCloudDatabase.delete(withRecordID: recordID) { recordID, error in
            DispatchQueue.main.async {
                
            }
        }
    }
    func updateSaveAllergens(recordID: CKRecord.ID,allergens: [String]) {
        let needToRemove = allergensObject.filter { !allergens.contains($0.allergen)
        }
        
        needToRemove.forEach {
            deleteAllergens(recordID: $0.record.recordID)
        }
        let objects = allergensObject.map { $0.allergen
        }
        let needToAdd = allergens.filter { !objects.contains($0) }
        for allergen in needToAdd {
//            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
//            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "Allergens")
            
            myRecord["allergen"] = allergen
            myRecord["totalNumberOfEpisodes"] = 0
            myRecord["totalNumberOfMedicalTests"] = 0
            
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            myRecord["profile"] = reference as CKRecordValue
            print("profileID: ", recordID.recordName)
            saveAllergen(record: myRecord)
        }
    }
    
    private func saveAllergen(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
        }
    }
    
    private func saveItem(record: CKRecord, completion: @escaping ((CKRecord.ID?)->Void)) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
            if let record = returnedRecord {
                DispatchQueue.main.async {
                    if !self.isUpdated {
                        NotificationCenter.default.post(name: NSNotification.Name.init("updateProfile"), object: MemberListModel(record: record))
                    }
                    PersistenceController.shared.addProfile(profile: record)
                }
            }
            completion(returnedRecord?.recordID)
        }
    }
    
    //MARK: - Fetching from CK Private DataBase Custom Zone
    
    func fetchItemsFromCloud() {
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "ProfileInfo", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.queuePriority = .veryHigh
        
//        self.profileInfo = []
        queryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let member = MemberListModel(record: returnedRecord) {
                    self.saveToLocalCache(member)
                    let exist = self.profileInfo.first(where: { $0.record.recordID.recordName == member.record.recordID.recordName                    })
                    if exist == nil {
                        self.profileInfo.append(member)
                    }
                }
            }
        }
        queryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED ProfileInto queryResultBlock")
        }
        addOperation(operation: queryOperation)
    }
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    //MARK: - UPDATE/EDIT @CK Private DataBase Custom Zone
    
    func updateItem() {
        guard let myRecord = record else { return }
        if let profileImage = getImageURL(for: data) {
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
        //            myRecord["allergens"] = allergens
        saveItem(record: myRecord) { [weak self, allergens] recordID in
            guard let recordID = recordID else { return }
            self?.updateSaveAllergens(recordID: recordID, allergens: allergens)
        }
    }
    
    
    //MARK: - DELETE CK @CK Private DataBase Custom Zone
    
    func deleteItemsFromCloud(record: CKRecord, completion: @escaping ((Bool)->Void)) {
        CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { recordID, error in
            DispatchQueue.main.async {
                completion(error == nil)
                if error == nil {
                    NotificationCenter.default.post(name: NSNotification.Name.init("updateProfile"), object: recordID)
                }
            }
        }
    }

}
