//
//  PersistenceController.swift
//  Guardian
//
//  Created by Teff on 2023/04/09.
//

import Foundation
import CoreData
import CloudKit
//import UIKit
//import Combine

class PersistenceController {
    private var workItem: DispatchWorkItem?
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
    
//    func fetchDiagnosis(profileID: String, allergen: String) -> [DiagnosisEntity] {
//        let fetchRequest = DiagnosisEntity.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "profileID == %@ AND %@ IN %K", profileID, allergen, "allergens")
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
//        do {
//            let fetchedItems = try context.fetch(fetchRequest)
//            return fetchedItems
//        } catch let error as NSError {
//            print("Could not fetch from local cache. \(error), \(error.userInfo)")
//        }
//        return []
//    }
    
    
  

    func fetchDiagnosis(profileID: String, allergen: String) -> [DiagnosisEntity] {
        let fetchRequest: NSFetchRequest<DiagnosisEntity> = DiagnosisEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profileID == %@", profileID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        do {
            let fetchedItems = try context.fetch(fetchRequest)
            
            // Filter the fetchedItems based on the allergen
            let filteredItems = fetchedItems.filter { diagnosisEntity in
                guard let allergensData = diagnosisEntity.allergens else {
                    return false
                }

                return allergensData.contains(allergen)
            }
            
            return filteredItems
        } catch let error as NSError {
            print("Could not fetch from local cache. \(error), \(error.userInfo)")
        }
        return []
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
    
    func fetchBloodTest(allergenID: String) -> [BloodTestEntity] {
        let fetchRequest = BloodTestEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "allergenID == %@", allergenID)
        do {
            let records = try context.fetch(fetchRequest)
            return records
        } catch let error as NSError {
            print("Could not fetch from local cache. \(error), \(error.userInfo)")
        }
        return []
    }
    
    func addBloodTest(record: CKRecord) {
        let entity = BloodTestEntity(context: container.viewContext)
        entity.update(with: record)
        saveContext()
    }
    func deleteBloodTest(recordID: String) {
        let fetchRequest = BloodTestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", recordID)
        
        do{
            let fetchedItems = try context.fetch(fetchRequest)
            if let itemToDelete = fetchedItems.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch let error as NSError {
            print("Counld not delete from local cache. \(error), \(error.userInfo)")
        }
    }
    
    func deleteBloodTest(recordIDs: [String]) {
        let fetchRequest = BloodTestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID IN %@", recordIDs)
        
        do{
            let fetchedItems = try context.fetch(fetchRequest)
            if let itemToDelete = fetchedItems.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch let error as NSError {
            print("Counld not delete from local cache. \(error), \(error.userInfo)")
        }
    }
    
    func fetchSkinTest(allergenID: String) -> [SkinTestEntity] {
        let fetchRequest = SkinTestEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "allergenID == %@", allergenID)
        do {
            let records = try context.fetch(fetchRequest)
            return records
        } catch let error as NSError {
            print("Could not fetch from local cache. \(error), \(error.userInfo)")
        }
        return []
    }
    
    func addSkinTest(record: CKRecord) {
        let entity = SkinTestEntity(context: container.viewContext)
        entity.update(with: record)
        saveContext()
    }
    func deleteSkinTest(recordID: String) {
        let fetchRequest = SkinTestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", recordID)
        
        do{
            let fetchedItems = try context.fetch(fetchRequest)
            if let itemToDelete = fetchedItems.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch let error as NSError {
            print("Counld not delete from local cache. \(error), \(error.userInfo)")
        }
    }
    
    func deleteSkinTest(recordIDs: [String]) {
        let fetchRequest = SkinTestEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID IN %@", recordIDs)
        
        do{
            let fetchedItems = try context.fetch(fetchRequest)
            if let itemToDelete = fetchedItems.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch let error as NSError {
            print("Counld not delete from local cache. \(error), \(error.userInfo)")
        }
    }
    
    func fetchOralFoodChallenge(allergenID: String) -> [OralFoodChallengeEntity] {
        let fetchRequest = OralFoodChallengeEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "allergenID == %@", allergenID)
        do {
            let records = try context.fetch(fetchRequest)
            return records
        } catch let error as NSError {
            print("Could not fetch from local cache. \(error), \(error.userInfo)")
        }
        return []
    }
    
    func addOralFoodChallenge(record: CKRecord) {
        let entity = OralFoodChallengeEntity(context: container.viewContext)
        entity.update(with: record)
        saveContext()
    }
    func deleteOralFoodChallenge(recordID: String) {
        let fetchRequest = OralFoodChallengeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", recordID)
        
        do{
            let fetchedItems = try context.fetch(fetchRequest)
            if let itemToDelete = fetchedItems.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch let error as NSError {
            print("Counld not delete from local cache. \(error), \(error.userInfo)")
        }
    }
    func deleteOralFoodChallenge(recordIDs: [String]) {
        let fetchRequest = OralFoodChallengeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID IN %@", recordIDs)
        
        do{
            let fetchedItems = try context.fetch(fetchRequest)
            if let itemToDelete = fetchedItems.first {
                context.delete(itemToDelete)
                try context.save()
            }
        } catch let error as NSError {
            print("Counld not delete from local cache. \(error), \(error.userInfo)")
        }
    }
    
    func exportAllRecordsToPDF(selectedProfile: ProfileInfoEntity, viewContext: NSManagedObjectContext, completion: @escaping (Result<URL, Error>) -> Void) {
        let workItem = DispatchWorkItem { [weak self] in
            let pdfExport = PDFExport(profile: selectedProfile, viewContext: viewContext)
            let pdfData = pdfExport.createPDF()
            // Save the PDF data to a file
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pdfFileName = "GuardianFoodAllergy_ExportedData.pdf"
            let pdfFileURL = documentDirectory.appendingPathComponent(pdfFileName)
            
            do {
                try pdfData.write(to: pdfFileURL)
                completion(.success(pdfFileURL))
            } catch {
                completion(.failure(error))
            }
        }
        self.workItem = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
    func cancelPDFGeneration() {
        workItem?.cancel()
        workItem = nil
    }
}
struct CancellationError: Error {}

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
        intakeAmount = record["intakeAmount"] as? String
        symptoms = record["symptoms"] as? [String]
        severity = record["severity"] as? String
        leadTimeToSymptoms = record["leadTimeToSymptoms"] as? String
        didExercise = record["didExercise"] as? Bool ?? false
        otherTreatment = record["otherTreatmemt"] as? String
        var imagePaths = [String]()
        if let images = record["data"] as? [CKAsset] {
            for image in images {
                if let fileURL = image.fileURL,
                   FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let name = String(format: "%@.jpg", fileURL.lastPathComponent)
                        let path = doc.appendingPathComponent(name)
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
extension BloodTestEntity {
    func update(with record: CKRecord) {
        self.recordID = record.recordID.recordName
        self.allergenID = (record["allergen"] as? CKRecord.Reference)?.recordID.recordName
        self.creationDate = record.creationDate
        bloodTestDate = record["bloodTestDate"] as? Date
        bloodTestLevel = record["bloodTestLevel"] as? String
        bloodTestGrade = record["bloodTestGrade"] as? String
    }
}
extension SkinTestEntity {
    func update(with record: CKRecord) {
        self.recordID = record.recordID.recordName
        self.allergenID = (record["allergen"] as? CKRecord.Reference)?.recordID.recordName
        self.creationDate = record.creationDate
        skinTestDate = record["skinTestDate"] as? Date
        skinTestResult = record["skinTestResult"] as? Bool ?? false
        skinTestResultValue = record["skinTestResultValue"] as? String
    }
}
extension OralFoodChallengeEntity {
    func update(with record: CKRecord) {
        self.recordID = record.recordID.recordName
        self.allergenID = (record["allergen"] as? CKRecord.Reference)?.recordID.recordName
        self.creationDate = record.creationDate
        oralFoodChallengeDate = record["oralFoodChallengeDate"] as? Date
        oralFoodChallengeQuantity = record["oralFoodChallengeQuantity"] as? String
        oralFoodChallengeResult = record["oralFoodChallengeResult"] as? Bool ?? false
    }
}
