//
//  AllergensModel.swift
//  Guardian
//
//  Created by Teff on 2023/03/29.
//

import CloudKit

struct AllergensModel: Identifiable, Hashable {
    
    let id = UUID()
    let allergen: String
    let record: CKRecord
    
    init?(record: CKRecord) {
        guard let name = record["allergen"] as? String else { return nil }
        allergen = name
        self.record = record
    }
}
