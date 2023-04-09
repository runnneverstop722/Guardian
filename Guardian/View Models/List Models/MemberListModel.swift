//
//  MemberListModel.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI
import PhotosUI
import CloudKit
import CoreData

struct MemberListModel: Identifiable, Hashable {
    
    let id = UUID()
    let headline: String
    let caption: String
    let imageURL: URL?
    let date: Date
    let record: CKRecord
    var image: Image? {
        if let url = imageURL,
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return Image(uiImage: image)
        }
        return nil
    }
    
    init?(record: CKRecord) {
        guard let firstName = record["firstName"] as? String else { return nil }
        guard let lastName = record["lastName"] as? String else { return nil }
        guard let birthDate = record["birthDate"] as? Date else { return nil}
        var fileURL: URL?
        if let profileImage = record["profileImage"] as? CKAsset {
            fileURL = profileImage.fileURL
            print("save url: model ", fileURL?.absoluteString)
        }
      
        headline = String(format: "%@ %@", firstName, lastName) // firstname + " " + lastname
        date = birthDate
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: .now)
        caption = String(format: "%d 歳", age.year!)
        imageURL = fileURL
        self.record = record
    }
    
    init?(entity: ProfileInfoEntity) {
        let myRecord = CKRecord(recordType: "ProfileInfo", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        if let profileImage = entity.profileImageData, let url = URL(string: profileImage) {
            let url = CKAsset(fileURL: url)
            myRecord["profileImage"] = url
        }
        myRecord["firstName"] = entity.firstName
        myRecord["lastName"] = entity.lastName
        myRecord["gender"] = entity.gender
        myRecord["birthDate"] = entity.birthDate
        myRecord["hospitalName"] = entity.hospitalName
        myRecord["allergist"] = entity.allergist
        myRecord["allergistContactInfo"] = entity.allergistContactInfo
        self.init(record: myRecord)
    }
}
