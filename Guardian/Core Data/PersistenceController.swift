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

    var context: NSManagedObjectContext {
        return container.viewContext
    }
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
    
    func addAllergen(allergen: CKRecord) {
        let entity = AllergenEntity(context: container.viewContext)
        entity.update(with: allergen)
        saveContext()
    }
    
    func deleteAllergen(recordID: String) {
        let fetchRequest = AllergenEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", recordID)

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
    
    func addDiagnosis(record: CKRecord) {
        let entity = DiagnosisEntity(context: container.viewContext)
        entity.update(with: record)
        saveContext()
    }
    
    func deleteDiagnosis(recordID: String) {
        let fetchRequest = DiagnosisEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", recordID)

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
    
    func addEpisode(record: CKRecord) {
        let entity = EpisodeEntity(context: container.viewContext)
        entity.update(with: record)
        saveContext()
    }
    
    func deleteEpisode(recordID: String) {
        let fetchRequest = EpisodeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", recordID)

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

extension AllergenEntity {
    func update(with record: CKRecord) {
        self.recordID = record.recordID.recordName
        self.allergen = record["allergen"] as? String
        self.profileID = (record["profile"] as? CKRecord.Reference)?.recordID.recordName
        self.totalNumberOfEpisodes = record["totalNumberOfEpisodes"] as? Int16 ?? 0
        self.totalNumberOfMedicalTests = record["totalNumberOfMedicalTests"] as? Int16 ?? 0
        self.creationDate = record.creationDate
    }
}

extension DiagnosisEntity {
    func update(with record: CKRecord) {
        self.recordID = record.recordID.recordName
        self.profileID = (record["profile"] as? CKRecord.Reference)?.recordID.recordName
        self.allergens = record["allergens"] as? [String]
        self.diagnosis = record["diagnosis"] as? String
        self.diagnosisDate = record["diagnosisDate"] as? Date
        self.diagnosedHospital = record["diagnosedHospital"] as? String
        self.diagnosedAllergist = record["diagnosedAllergist"] as? String
        self.diagnosedAllergistComment = record["diagnosedAllergistComment"] as? String
        self.creationDate = record.creationDate
        var imagePaths = [String]()
        if let images = record["data"] as? [CKAsset] {
            for image in images {
                if let fileURL = image.fileURL,
                   FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let name = String(format: "%@.jpg", fileURL.lastPathComponent)
                        let path = doc.appendingPathComponent(name)
                        //                    if FileManager.default.fileExists(atPath: path.path) {
                        //                        self.profileImageData = name
                        //                    } else {
                        //                    }
                        try? FileManager.default.removeItem(at: path)
                        try FileManager.default.copyItem(at: fileURL, to: path)
                        imagePaths.append(name)
                        print("save URL: ", path.path)
                    } catch {
                        
                    }
                }
            }
        }
        self.diagnosisPhoto = imagePaths
    }
}
extension EpisodeEntity {
    func update(with record: CKRecord) {
        self.recordID = record.recordID.recordName
        self.allergenID = (record["allergen"] as? CKRecord.Reference)?.recordID.recordName
        self.creationDate = record.creationDate
        episodeDate = record["episodeDate"] as? Date
        firstKnownExposure = record["firstKnownExposure"] as? Bool ?? false
        wentToHospital = record["wentToHospital"] as? Bool ?? false
        typeOfExposure = record["typeOfExposure"] as? [String]
        symptoms = record["symptoms"] as? [String]
        self.severity = record["severity"] as? String
        leadTimeToSymptoms = record["leadTimeToSymptoms"] as? String
        didExercise = record["didExercise"] as? Bool ?? false
        var imagePaths = [String]()
        if let images = record["data"] as? [CKAsset] {
            for image in images {
                if let fileURL = image.fileURL,
                   FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let name = String(format: "%@.jpg", fileURL.lastPathComponent)
                        let path = doc.appendingPathComponent(name)
                        //                    if FileManager.default.fileExists(atPath: path.path) {
                        //                        self.profileImageData = name
                        //                    } else {
                        //                    }
                        try? FileManager.default.removeItem(at: path)
                        try FileManager.default.copyItem(at: fileURL, to: path)
                        imagePaths.append(name)
                        print("save URL: ", path.path)
                    } catch {
                        
                    }
                }
            }
        }
        self.episodePhoto = imagePaths
    }
}
