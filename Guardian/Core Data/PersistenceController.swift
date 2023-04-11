//
//  PersistenceController.swift
//  Guardian
//
//  Created by Teff on 2023/04/09.
//

import CoreData
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ProfileContainer")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = NSPersistentContainer.defaultDirectoryURL() .appendingPathComponent("ProfileContainer.sqlite")
        container.persistentStoreDescriptions = [description]
        container.viewContext.mergePolicy = NSMergePolicy.overwrite
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    func addProfile(profile: CKRecord) {
        let entity = ProfileInfoEntity(context: container.viewContext)
        entity.update(with: profile)
        saveContext()
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension ProfileInfoEntity {
    func update(with record: CKRecord) {
        
        self.recordID = record.recordID.recordName
        self.firstName = record["firstName"] as? String
        self.lastName = record["lastName"] as? String
        self.gender = record["gender"] as? String
        self.birthDate = record["birthDate"] as? Date
        self.hospitalName = record["hospitalName"] as? String
        self.allergist = record["allergist"] as? String
        self.allergistContactInfo = record["allergistContactInfo"] as? String
        self.creationDate = record.creationDate
        if let profileImage = record["profileImage"] as? CKAsset, let fileURL = profileImage.fileURL {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let name = String(format: "%@.jpg", self.recordID!)
                    let path = doc.appendingPathComponent(name)
//                    if FileManager.default.fileExists(atPath: path.path) {
//                        self.profileImageData = name
//                    } else {
//                    }
                    try? FileManager.default.removeItem(at: path)
                    try FileManager.default.copyItem(at: fileURL, to: path)
                    self.profileImageData = name
                    print("save URL: ", path.path)
                } catch {
                    
                }
            }
        } else {
            self.profileImageData = nil
        }
    }
}
