//
//  CoreDataViewModel.swift
//  Guardian
//
//  Created by Teff on 2023/04/08.
//

import Foundation
import CoreData

class CoreDataViewModel: ObservableObject {
    let container: NSPersistentContainer
    @Published var savedEntities: [ProfileEntity] = []
    
    init() {
        container = NSPersistentContainer(name: "ProfileContainer")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error loading core data. \(error)")
            }
        }
        fetchProfile()
    }
    
    func fetchProfile() {
        let request = NSFetchRequest<ProfileEntity>(entityName: "ProfileEntity")
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            print("Error fetching. \(error)")
        }
    }
    
    func addProfile(entity: ProfileEntity) {
        let newProfileInfo = ProfileEntity(context: container.viewContext)
        newProfileInfo.firstName = entity.firstName
        newProfileInfo.lastName = entity.lastName
        newProfileInfo.gender = entity.gender
        newProfileInfo.birthDate = entity.birthDate
        newProfileInfo.hospitalName = entity.hospitalName
        newProfileInfo.allergist = entity.allergist
        newProfileInfo.allergistContactInfo = entity.allergistContactInfo
        saveData()
    }
    
    func saveData() {
        do {
            try container.viewContext.save()
            fetchProfile()
        } catch let error {
            print("Error saving. \(error)")
        }
    }
}
