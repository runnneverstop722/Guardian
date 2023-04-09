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
        if let profileImage = record["profileImage"] as? CKAsset {
            self.profileImageData = profileImage.fileURL?.absoluteString
            print("save URL: ", profileImage.fileURL?.absoluteString)
        } else {            
            self.profileImageData = nil
        }
    }
}
